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
import {NativeArbitrumImpl} from "../../../../../src/bridges/arbitrum/l1/NativeArbitrum.sol";
import {RefuelSwapAndBridgeController} from "../../../../../src/controllers/RefuelSwapAndBridgeController.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../../../src/errors/SocketErrors.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract NativeArbNativetoERC20RefuelSwapAndBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    SocketGateway internal socketGateway;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant stranger = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address public constant REFUEL_BRIDGE =
        0xb584D4bE1A5470CA1a8778E9B86c81e165204599;
    address public immutable ONEINCH_AGGREGATOR =
        0x1111111254EEB25477B68fb85Ed929f73A960582;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    struct SwapRequest {
        uint32 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    RefuelSwapAndBridgeController refuelSwapAndBridgeController;
    RefuelBridgeImpl internal refuelBridgeImpl;
    OneInchImpl internal oneInchImpl;
    NativeArbitrumImpl internal arbImpl;
    address constant nativeArbitrumRouterAddress =
        0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;
    address gatewayAddress = 0xcEe284F754E854890e311e3280b767F80797180d;
    uint256 maxGas = 357500;
    uint256 gasPriceBid = 300000000;
    uint256 bridgeAmount = 1000e6;
    uint256 bridgeValue = 278865580944192 + (357500 * 300000000);

    // uint256 bridgeValue = 278865580944192;
    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16995925);
        vm.selectFork(fork);

        socketGateway = createSocketGateway();
        vm.startPrank(owner);

        refuelBridgeImpl = new RefuelBridgeImpl(
            REFUEL_BRIDGE,
            address(socketGateway),
            address(socketGateway)
        );
        // address route_0 = address(refuelBridgeImpl);
        address route_0 = address(refuelBridgeImpl);

        socketGateway.addRoute(route_0);

        oneInchImpl = new OneInchImpl(
            ONEINCH_AGGREGATOR,
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(oneInchImpl);
        socketGateway.addRoute(route_1);

        arbImpl = new NativeArbitrumImpl(
            nativeArbitrumRouterAddress,
            address(socketGateway),
            address(socketGateway)
        );
        address route_2 = address(arbImpl);
        socketGateway.addRoute(route_2);

        refuelSwapAndBridgeController = new RefuelSwapAndBridgeController(
            address(socketGateway)
        );
        socketGateway.addController(address(refuelSwapAndBridgeController));

        vm.stopPrank();
    }

    function testRefuelSwapBridgeNativeToERC20() public {
        uint256 refuelAmount = 1e18;
        bytes
            memory data = hex"0000000000000000000000000000000000000000000000000000fda073e46b4000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000";

        //sequence of arguments for implData: _amount, _receiverAddress, _toChainId
        bytes memory refuelImplData = abi.encodeWithSelector(
            refuelBridgeImpl.REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            refuelAmount,
            receiver,
            56,
            metadata
        );

        SwapRequest memory swapRequest;

        swapRequest.id = 1;
        swapRequest
            .receiverAddress = 0x8657AB84A5B7Fc75B9327d6248cA398FA25D6712;
        swapRequest.amount = 1e16;
        swapRequest.inputToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        swapRequest.toToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        swapRequest.data = bytes(
            hex"0502b1c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000b82ced0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340b4e16d0168e52d35cacd2c6185b44281ec28c9dccfee7c08"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes
            memory swapImplData = hex"a2c7302c000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c80502b1c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000001172b5e0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b5dc1003926a168c11a816e10c13977f75f488bfffe88e4733d4004000000000000000000000000000000000000000000000000";

        // uint32 bridgeRouteId = 2;
        NativeArbitrumImpl.NativeArbitrumBridgeData memory nativeArbData;
        // HopImplL1.HopData memory hopExtraData;
        // hopExtraData.receiverAddress = receiver;
        // hopExtraData.token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        // hopExtraData.toChainId = 42161;
        // hopExtraData.l1bridgeAddr = 0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
        // hopExtraData.relayer = 0x0000000000000000000000000000000000000000;
        // hopExtraData.amountOutMin = 290e6;
        // hopExtraData.relayerFee = 0;
        // hopExtraData.deadline = block.timestamp + 100000;
        // hopExtraData.metadata = metadata;
        nativeArbData.value = bridgeValue;
        nativeArbData.maxGas = maxGas;
        nativeArbData.gasPriceBid = gasPriceBid;
        nativeArbData.receiverAddress = receiver;
        nativeArbData
            .gatewayAddress = 0xcEe284F754E854890e311e3280b767F80797180d;
        nativeArbData.token = USDC;
        nativeArbData.metadata = metadata;
        nativeArbData.data = data;
        bytes memory nativeArbDataBytes = abi.encode(nativeArbData);
        // bytes memory eventData = abi.encodePacked("RefuelSwapAndBridgeNative");

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory controllerImplData = abi.encodeWithSelector(
            refuelSwapAndBridgeController
                .REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR(),
            ISocketRequest.RefuelSwapBridgeRequest(
                9,
                refuelImplData,
                12,
                swapImplData,
                5,
                nativeArbDataBytes
            )
        );

        vm.startPrank(sender1);
        deal(sender1, refuelAmount + swapRequest.amount + bridgeValue);

        ISocketGateway.SocketControllerRequest memory socketControllerRequest;
        socketControllerRequest.controllerId = 0;
        socketControllerRequest.data = controllerImplData;
        console.log("address", address(socketGateway));
        console.log(
            "address",
            sender1.balance,
            refuelAmount + swapRequest.amount + bridgeValue
        );
        console.log(3175386000000000 + 32179196002966526 + 706334369380544);
        SocketGateway(payable(0x3a23F943181408EAC424116Af7b7790c94Cb97a5))
            .executeController{
            value: refuelAmount + swapRequest.amount + bridgeValue
        }(socketControllerRequest);

        vm.stopPrank();
    }
}
