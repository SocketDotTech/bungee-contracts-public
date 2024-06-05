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
import {RefuelBridgeImpl} from "../../../../../src/bridges/refuel/refuel.sol";
import {OneInchImpl} from "../../../../../src/swap/oneinch/OneInchImpl.sol";
import {HopImplL1} from "../../../../../src/bridges/hop/l1/HopImplL1.sol";
import {FeesTakerController} from "../../../../../src/controllers/FeesTakerController.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../../../src/errors/SocketErrors.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract ERC20FeesRefuelSwapAndBridgeTest is Test, SocketGatewayBaseTest {
    using SafeTransferLib for ERC20;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant integrator = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant feesTakerAddress =
        0x8ABF8B2353CC86aC253394bb0a9cEb030Fcf1ac6;
    address constant receiver = 0x810396ca96cc1406Ad6663E1C8f85D9c91acB89B;
    address public constant REFUEL_BRIDGE =
        0xb584D4bE1A5470CA1a8778E9B86c81e165204599;
    address public immutable ONEINCH_AGGREGATOR =
        0x1111111254EEB25477B68fb85Ed929f73A960582;

    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    SocketGateway internal socketGateway;
    FeesTakerController feesTakerController;
    RefuelBridgeImpl internal refuelBridgeImpl;
    OneInchImpl internal oneInchImpl;
    HopImplL1 hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16257296);
        vm.selectFork(fork);

        socketGateway = createSocketGateway();
        vm.startPrank(owner);

        refuelBridgeImpl = new RefuelBridgeImpl(
            REFUEL_BRIDGE,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(refuelBridgeImpl);
        socketGateway.addRoute(route_0);

        oneInchImpl = new OneInchImpl(
            ONEINCH_AGGREGATOR,
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(oneInchImpl);
        socketGateway.addRoute(route_1);

        hopBridgeImpl = new HopImplL1(
            address(socketGateway),
            address(socketGateway)
        );
        address route_2 = address(hopBridgeImpl);
        socketGateway.addRoute(route_2);

        feesTakerController = new FeesTakerController(address(socketGateway));
        socketGateway.addController(address(feesTakerController));

        vm.stopPrank();
    }

    function testERC20RefuelAndFeesAndSwapAndBridge() public {
        uint256 amount = 103e6;
        uint256 swapAmount = 100e6;
        uint256 feesAmount = 3e6;
        address token = USDC;

        deal(address(token), integrator, amount);
        assertEq(ERC20(token).balanceOf(integrator), amount);

        uint256 refuelAmount = 1e16;

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory refuelImplData = abi.encodeWithSelector(
            refuelBridgeImpl.REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            refuelAmount,
            receiver,
            56,
            metadata
        );

        deal(integrator, refuelAmount);

        SwapRequest memory swapRequest;

        swapRequest.id = 1;
        swapRequest
            .receiverAddress = 0x8657AB84A5B7Fc75B9327d6248cA398FA25D6712;
        swapRequest.amount = swapAmount;
        swapRequest.inputToken = token;
        swapRequest.toToken = NATIVE_TOKEN_ADDRESS;

        //https://api.1inch.io/v5.0/1/swap?fromTokenAddress=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&toTokenAddress=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&amount=100000000&fromAddress=0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f&slippage=1&disableEstimate=true
        swapRequest.data = bytes(
            hex"e449022e0000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000001226d0eab6d5f470000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000120000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f5640cfee7c08"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory swapImplData = abi.encodeWithSelector(
            oneInchImpl.SWAP_WITHIN_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.data
        );

        HopImplL1.HopData memory hopData;
        hopData.receiverAddress = receiver;
        hopData.token = NATIVE_TOKEN_ADDRESS;
        hopData.l1bridgeAddr = 0xb8901acB165ed027E32754E0FFe830802919727f;
        hopData.relayer = 0x0000000000000000000000000000000000000000;
        hopData.amountOutMin = 0;
        hopData.relayerFee = 0;
        hopData.toChainId = 42161;
        hopData.deadline = block.timestamp + 100000;
        hopData.metadata = metadata;
        bytes memory hopDataBytes = abi.encode(hopData);
        bytes memory eventData = abi.encodePacked(
            "DeductERC20FeesRefuelSwapAndBridge"
        );

        ISocketRequest.FeesTakerRefuelSwapBridgeRequest
            memory feesRefuelSwapBridgeRequest = ISocketRequest
                .FeesTakerRefuelSwapBridgeRequest({
                    feesTakerAddress: feesTakerAddress,
                    feesToken: token,
                    feesAmount: feesAmount,
                    refuelRouteId: 513,
                    refuelData: refuelImplData,
                    swapRouteId: 514,
                    swapData: swapImplData,
                    bridgeRouteId: 515,
                    bridgeData: hopDataBytes
                });

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory controllerImplData = abi.encodeWithSelector(
            feesTakerController
                .FEES_TAKER_REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR(),
            feesRefuelSwapBridgeRequest
        );

        ISocketGateway.SocketControllerRequest memory socketControllerRequest;
        socketControllerRequest.controllerId = 0;
        socketControllerRequest.data = controllerImplData;

        assertEq(ERC20(token).balanceOf(integrator), amount);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(address(feesTakerAddress)), 0);
        assertEq(ERC20(token).balanceOf(receiver), 0);

        vm.startPrank(integrator);

        ERC20(token).safeApprove(address(socketGateway), amount);

        // Emits Event

        // assert for SocketBridge Event in refuel route
        emit SocketBridge(
            refuelAmount,
            NATIVE_TOKEN_ADDRESS,
            56,
            REFUEL,
            integrator,
            receiver
        );

        // assert for SocketSwapTokens Event in OneInch Swap route
        uint256 expected_Swapped_Amount = 81780273185908446;
        emit SocketSwapTokens(
            swapRequest.inputToken,
            swapRequest.toToken,
            expected_Swapped_Amount,
            swapRequest.amount,
            ONEINCH,
            address(socketGateway)
        );

        // assert for SocketBridge Event in HopL1 route
        emit SocketBridge(
            expected_Swapped_Amount,
            NATIVE_TOKEN_ADDRESS,
            hopData.toChainId,
            HOP,
            integrator,
            hopData.receiverAddress
        );

        socketGateway.executeController{value: refuelAmount}(
            socketControllerRequest,
            eventData
        );

        vm.stopPrank();

        assertEq(ERC20(token).balanceOf(integrator), 0);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(feesTakerAddress), feesAmount);
        assertEq(ERC20(token).balanceOf(receiver), 0);
    }
}
