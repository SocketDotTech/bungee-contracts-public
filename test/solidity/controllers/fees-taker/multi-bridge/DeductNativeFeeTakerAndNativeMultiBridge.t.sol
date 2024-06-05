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
import {AcrossImpl} from "../../../../../src/bridges/across/Across.sol";
import {FeesTakerController} from "../../../../../src/controllers/FeesTakerController.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../../../src/errors/SocketErrors.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract DeductNativeFeeTakerAndNativeMultiBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    using SafeTransferLib for ERC20;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    address constant integrator = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant feesTakerAddress =
        0x8ABF8B2353CC86aC253394bb0a9cEb030Fcf1ac6;
    address constant hop_receiver = 0x810396ca96cc1406Ad6663E1C8f85D9c91acB89B;
    address constant across_receiver =
        0x7B0002478DaCc0338E4C07172339e38518696ad2;
    address constant spokePoolAddress =
        0x4D9079Bb4165aeb4084c526a32695dCfd2F77381;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    SocketGateway internal socketGateway;
    FeesTakerController feesTakerController;
    HopImplL1 hopBridgeImpl;
    AcrossImpl internal acrossImpl;
    uint32 hopBridgeRouteId;
    uint32 acrossRouteId;

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

    struct AcrossBridgeRequestData {
        address bridgeToken;
        uint256 bridgeAmount;
        uint256 destinationChain;
        address receiver;
        uint64 _relayerFeePct;
        uint32 _quoteTimestamp;
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

        acrossImpl = new AcrossImpl(
            spokePoolAddress,
            WETH,
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(acrossImpl);
        socketGateway.addRoute(route_1);
        acrossRouteId = 1;

        feesTakerController = new FeesTakerController(address(socketGateway));

        socketGateway.addController(address(feesTakerController));

        vm.stopPrank();
    }

    function testTakeNativeFeesAndNativeMultiBridge() public {
        // Build HopBridgeRequest Data
        HopBridgeRequestData memory hopBridgeRequestData;
        hopBridgeRequestData
            ._l1bridgeAddr = 0xb8901acB165ed027E32754E0FFe830802919727f;
        hopBridgeRequestData
            ._relayer = 0x0000000000000000000000000000000000000000;
        hopBridgeRequestData._amountOutMin = 0;
        hopBridgeRequestData._relayerFee = 0;
        hopBridgeRequestData._deadline = block.timestamp + 100000;
        hopBridgeRequestData.bridgeToken = NATIVE_TOKEN_ADDRESS;
        hopBridgeRequestData.bridgeAmount = 30e18;
        hopBridgeRequestData.destinationChain = 42161;
        hopBridgeRequestData.receiver = hop_receiver;

        bytes memory hop_bridgeImplData = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            hopBridgeRequestData.receiver,
            hopBridgeRequestData._l1bridgeAddr,
            hopBridgeRequestData._relayer,
            hopBridgeRequestData.destinationChain,
            hopBridgeRequestData.bridgeAmount,
            hopBridgeRequestData._amountOutMin,
            hopBridgeRequestData._relayerFee,
            hopBridgeRequestData._deadline,
            metadata
        );

        // Build NativeAritrumBridgeRequest Data
        AcrossBridgeRequestData memory acrossBridgeRequestData;

        acrossBridgeRequestData.bridgeToken = NATIVE_TOKEN_ADDRESS;
        acrossBridgeRequestData.bridgeAmount = 1e18;
        acrossBridgeRequestData.destinationChain = 10;
        acrossBridgeRequestData.receiver = across_receiver;
        acrossBridgeRequestData._relayerFeePct = 0;
        acrossBridgeRequestData._quoteTimestamp = uint32(block.timestamp);

        bytes memory across_bridgeImplData = abi.encodeWithSelector(
            acrossImpl.ACROSS_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            acrossBridgeRequestData.bridgeAmount,
            acrossBridgeRequestData.destinationChain,
            metadata,
            acrossBridgeRequestData.receiver,
            acrossBridgeRequestData._quoteTimestamp,
            acrossBridgeRequestData._relayerFeePct
        );

        FeesData memory feesData;
        feesData.feesToken = NATIVE_TOKEN_ADDRESS;
        feesData.feesAmount = 1e16;

        // Fund integrator with native balance
        uint256 totalNativeFunding = feesData.feesAmount +
            hopBridgeRequestData.bridgeAmount +
            acrossBridgeRequestData.bridgeAmount;
        deal(integrator, totalNativeFunding);
        assertEq(integrator.balance, totalNativeFunding);
        assertEq(address(socketGateway).balance, 0);
        assertEq(feesTakerAddress.balance, 0);
        assertEq(hop_receiver.balance, 0);
        assertEq(across_receiver.balance, 0);

        uint32[] memory bridgeRouteIds = new uint32[](2);
        bridgeRouteIds[0] = 513;
        bridgeRouteIds[1] = 514;

        bytes[] memory eventDataItems = new bytes[](2);
        eventDataItems[0] = abi.encodePacked("HopBridge");
        eventDataItems[1] = abi.encodePacked("AcrossBridge");
        bytes memory eventData = abi.encode(eventDataItems);

        bytes[] memory bridgeImplementationDataItems = new bytes[](2);
        bridgeImplementationDataItems[0] = hop_bridgeImplData;
        bridgeImplementationDataItems[1] = across_bridgeImplData;

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

        socketGateway.executeController{value: totalNativeFunding}(
            socketControllerRequest,
            eventData
        );

        vm.stopPrank();

        assertEq(integrator.balance, 0);
        assertEq(address(socketGateway).balance, 0);
        assertEq(feesTakerAddress.balance, feesData.feesAmount);
        assertEq(hop_receiver.balance, 0);
        assertEq(across_receiver.balance, 0);
    }
}
