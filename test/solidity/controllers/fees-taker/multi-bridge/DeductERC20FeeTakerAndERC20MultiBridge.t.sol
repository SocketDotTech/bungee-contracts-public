// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {ISocketController} from "../../../../../src/interfaces/ISocketController.sol";
import {ISocketGateway} from "../../../../../src/interfaces/ISocketGateway.sol";
import {ISocketRequest} from "../../../../../src/interfaces/ISocketRequest.sol";
import {NativeArbitrumImpl} from "../../../../../src/bridges/arbitrum/l1/NativeArbitrum.sol";
import {HopImplL1} from "../../../../../src/bridges/hop/l1/HopImplL1.sol";
import {FeesTakerController} from "../../../../../src/controllers/FeesTakerController.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../../../src/errors/SocketErrors.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract DeductERC20FeeTakerAndERC20MultiBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    using SafeTransferLib for ERC20;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant integrator = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant feesTakerAddress =
        0x8ABF8B2353CC86aC253394bb0a9cEb030Fcf1ac6;
    address constant hop_receiver = 0x810396ca96cc1406Ad6663E1C8f85D9c91acB89B;
    address constant nativeArbitrum_receiver =
        0xcb7387fCC70801619678842d11F007e847DBd2e7;
    address constant nativeArbitrumRouterAddress =
        0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;

    SocketGateway internal socketGateway;
    FeesTakerController feesTakerController;
    HopImplL1 hopBridgeImpl;
    uint32 hopBridgeRouteId;
    NativeArbitrumImpl internal nativeArbitrumImpl;
    uint32 nativeArbitrumRouteId;

    struct FeesData {
        address feesToken;
        uint256 feesAmount;
    }

    struct HopBridgeRequestData {
        address bridgeToken;
        uint256 bridgeAmount;
        uint256 destinationChain;
        address receiver;
        address _l1bridgeAddr;
        address _relayer;
        uint256 _amountOutMin;
        uint256 _relayerFee;
        uint256 _deadline;
    }

    struct NativeArbitrumBridgeRequestData {
        address bridgeToken;
        uint256 bridgeAmount;
        address receiver;
        address gatewayAddress;
        uint256 maxGas;
        uint256 gasPriceBid;
        bytes data;
        uint256 bridgeValue;
    }

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16257296);
        vm.selectFork(fork);

        socketGateway = createSocketGateway();
        vm.startPrank(owner);

        hopBridgeImpl = new HopImplL1(
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(hopBridgeImpl);
        socketGateway.addRoute(route_0);
        hopBridgeRouteId = 0;

        nativeArbitrumImpl = new NativeArbitrumImpl(
            nativeArbitrumRouterAddress,
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(nativeArbitrumImpl);
        socketGateway.addRoute(route_1);
        nativeArbitrumRouteId = 1;

        feesTakerController = new FeesTakerController(address(socketGateway));

        socketGateway.addController(address(feesTakerController));

        vm.stopPrank();
    }

    function testERC20FeesAndMultiBridge() public {
        FeesData memory feesData;

        feesData.feesToken = USDC;
        feesData.feesAmount = 10e6;

        deal(address(feesData.feesToken), integrator, feesData.feesAmount);
        assertEq(
            IERC20(feesData.feesToken).balanceOf(integrator),
            feesData.feesAmount
        );

        // Build HopBridgeRequest Data
        HopBridgeRequestData memory hopBridgeRequestData;
        hopBridgeRequestData
            ._l1bridgeAddr = 0x3E4a3a4796d16c0Cd582C382691998f7c06420B6;
        hopBridgeRequestData
            ._relayer = 0x0000000000000000000000000000000000000000;
        hopBridgeRequestData._amountOutMin = 290e18;
        hopBridgeRequestData._relayerFee = 0;
        hopBridgeRequestData._deadline = block.timestamp + 100000;
        hopBridgeRequestData.bridgeToken = USDT;
        hopBridgeRequestData.bridgeAmount = 300e18;
        hopBridgeRequestData.destinationChain = 42161;
        hopBridgeRequestData.receiver = hop_receiver;

        deal(
            address(hopBridgeRequestData.bridgeToken),
            integrator,
            hopBridgeRequestData.bridgeAmount
        );
        assertEq(
            IERC20(hopBridgeRequestData.bridgeToken).balanceOf(integrator),
            hopBridgeRequestData.bridgeAmount
        );

        bytes memory hop_bridgeImplData = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            hopBridgeRequestData.receiver,
            hopBridgeRequestData.bridgeToken,
            hopBridgeRequestData._l1bridgeAddr,
            hopBridgeRequestData._relayer,
            hopBridgeRequestData.destinationChain,
            hopBridgeRequestData.bridgeAmount,
            hopBridgeRequestData._amountOutMin,
            hopBridgeRequestData._relayerFee,
            HopImplL1.HopERC20Data(hopBridgeRequestData._deadline, metadata)
        );

        // Build NativeAritrumBridgeRequest Data
        NativeArbitrumBridgeRequestData memory nativeArbitrumBridgeRequestData;
        nativeArbitrumBridgeRequestData
            .gatewayAddress = 0xD3B5b60020504bc3489D6949d545893982BA3011;
        nativeArbitrumBridgeRequestData.maxGas = 357500;
        nativeArbitrumBridgeRequestData.gasPriceBid = 300000000;
        nativeArbitrumBridgeRequestData
            .data = hex"000000000000000000000000000000000000000000000000000097d65f01cc4000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000";
        nativeArbitrumBridgeRequestData.bridgeValue = 274196972748864;
        nativeArbitrumBridgeRequestData.bridgeToken = DAI;
        nativeArbitrumBridgeRequestData.bridgeAmount = 650e18;
        nativeArbitrumBridgeRequestData.receiver = nativeArbitrum_receiver;

        deal(
            address(nativeArbitrumBridgeRequestData.bridgeToken),
            integrator,
            nativeArbitrumBridgeRequestData.bridgeAmount
        );
        assertEq(
            IERC20(nativeArbitrumBridgeRequestData.bridgeToken).balanceOf(
                integrator
            ),
            nativeArbitrumBridgeRequestData.bridgeAmount
        );
        deal(integrator, nativeArbitrumBridgeRequestData.bridgeValue);
        assertEq(
            integrator.balance,
            nativeArbitrumBridgeRequestData.bridgeValue
        );

        //sequence of arguments for implData: receiverAddress, token, gatewayAddress, amount, value, maxGas, gasPriceBid, data
        bytes memory nativeArbitrum_bridgeImplData = abi.encodeWithSelector(
            nativeArbitrumImpl
                .NATIVE_ARBITRUM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            nativeArbitrumBridgeRequestData.bridgeAmount,
            nativeArbitrumBridgeRequestData.bridgeValue,
            nativeArbitrumBridgeRequestData.maxGas,
            nativeArbitrumBridgeRequestData.gasPriceBid,
            metadata,
            nativeArbitrumBridgeRequestData.receiver,
            nativeArbitrumBridgeRequestData.bridgeToken,
            nativeArbitrumBridgeRequestData.gatewayAddress,
            nativeArbitrumBridgeRequestData.data
        );

        uint32[] memory bridgeRouteIds = new uint32[](2);
        bridgeRouteIds[0] = 513;
        bridgeRouteIds[1] = 514;

        bytes[] memory bridgeImplementationDataItems = new bytes[](2);
        bridgeImplementationDataItems[0] = hop_bridgeImplData;
        bridgeImplementationDataItems[1] = nativeArbitrum_bridgeImplData;

        ISocketRequest.FeesTakerMultiBridgeRequest
            memory feesTakerMultiBridgeRequest = ISocketRequest
                .FeesTakerMultiBridgeRequest({
                    feesTakerAddress: feesTakerAddress,
                    feesToken: feesData.feesToken,
                    feesAmount: feesData.feesAmount,
                    bridgeRouteIds: bridgeRouteIds,
                    bridgeRequestDataItems: bridgeImplementationDataItems
                });

        //sequence of arguments for implData:  feesTakerAddress,token,feesAmount,bridgeAmount,routeId,bridgeRequestData
        bytes memory controllerImplData = abi.encodeWithSelector(
            feesTakerController.FEES_TAKER_MULTI_BRIDGE_FUNCTION_SELECTOR(),
            feesTakerMultiBridgeRequest
        );

        ISocketGateway.SocketControllerRequest memory socketControllerRequest;
        socketControllerRequest.controllerId = 0;
        socketControllerRequest.data = controllerImplData;

        vm.startPrank(integrator);

        ERC20(feesData.feesToken).safeApprove(
            address(socketGateway),
            feesData.feesAmount
        );
        ERC20(hopBridgeRequestData.bridgeToken).safeApprove(
            address(socketGateway),
            hopBridgeRequestData.bridgeAmount
        );
        ERC20(nativeArbitrumBridgeRequestData.bridgeToken).safeApprove(
            address(socketGateway),
            nativeArbitrumBridgeRequestData.bridgeAmount
        );

        bytes[] memory eventDataItems = new bytes[](2);
        eventDataItems[0] = abi.encodePacked("HopBridge");
        eventDataItems[1] = abi.encodePacked("AcrossBridge");
        bytes memory eventData = abi.encode(eventDataItems);

        socketGateway.executeController{
            value: nativeArbitrumBridgeRequestData.bridgeValue
        }(socketControllerRequest, eventData);

        vm.stopPrank();

        assertEq(ERC20(feesData.feesToken).balanceOf(integrator), 0);
        assertEq(
            ERC20(hopBridgeRequestData.bridgeToken).balanceOf(integrator),
            0
        );
        assertEq(
            ERC20(nativeArbitrumBridgeRequestData.bridgeToken).balanceOf(
                integrator
            ),
            0
        );

        assertEq(
            ERC20(feesData.feesToken).balanceOf(address(socketGateway)),
            0
        );
        assertEq(
            ERC20(hopBridgeRequestData.bridgeToken).balanceOf(
                address(socketGateway)
            ),
            0
        );
        assertEq(
            ERC20(nativeArbitrumBridgeRequestData.bridgeToken).balanceOf(
                address(socketGateway)
            ),
            0
        );

        assertEq(
            ERC20(feesData.feesToken).balanceOf(feesTakerAddress),
            feesData.feesAmount
        );

        assertEq(
            ERC20(hopBridgeRequestData.bridgeToken).balanceOf(
                hopBridgeRequestData.receiver
            ),
            0
        );
        assertEq(
            ERC20(nativeArbitrumBridgeRequestData.bridgeToken).balanceOf(
                nativeArbitrumBridgeRequestData.receiver
            ),
            0
        );

        assertEq(integrator.balance, 0);
    }
}
