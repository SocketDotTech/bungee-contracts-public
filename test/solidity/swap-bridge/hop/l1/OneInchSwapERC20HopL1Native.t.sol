// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {OneInchImpl} from "../../../../../src/swap/oneinch/OneInchImpl.sol";
import {HopImplL1} from "../../../../../src/bridges/hop/l1/HopImplL1.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../../src/interfaces/ISocketRequest.sol";

contract OneInchSwapERC20HopL1NativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
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

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    OneInchImpl internal OneInch;
    HopImplL1 internal hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16219787);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        OneInch = new OneInchImpl(
            0x1111111254EEB25477B68fb85Ed929f73A960582,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(OneInch);
        // Emits Event
        emit NewRouteAdded(0, route_0);

        socketGateway.addRoute(route_0);

        hopBridgeImpl = new HopImplL1(
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(hopBridgeImpl);
        socketGateway.addRoute(route_1);

        vm.stopPrank();
    }

    function testSocketGatewaySwapAndBridge() public {
        vm.startPrank(sender1);

        SwapRequest memory swapRequest;

        swapRequest.id = 513;
        swapRequest
            .receiverAddress = 0x8657AB84A5B7Fc75B9327d6248cA398FA25D6712;
        swapRequest.amount = 100e6;
        swapRequest.inputToken = USDC;
        swapRequest.toToken = NATIVE_TOKEN_ADDRESS;

        //https://api.1inch.io/v5.0/1/swap?fromTokenAddress=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&toTokenAddress=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&amount=100000000&fromAddress=0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f&slippage=1&disableEstimate=true
        swapRequest.data = bytes(
            hex"e449022e0000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000001226d0eab6d5f470000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000120000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f5640cfee7c08"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory swapImplData = abi.encodeWithSelector(
            OneInch.SWAP_WITHIN_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.data
        );

        uint32 bridgeRouteId = 514;
        HopImplL1.HopDataNoToken memory hopData;
        // hopData.token = NATIVE_TOKEN_ADDRESS;
        hopData.receiverAddress = sender1;
        hopData.l1bridgeAddr = 0xb8901acB165ed027E32754E0FFe830802919727f;
        hopData.relayer = 0x0000000000000000000000000000000000000000;
        hopData.amountOutMin = 0;
        hopData.relayerFee = 0;
        hopData.toChainId = 42161;
        hopData.deadline = block.timestamp + 100000;
        hopData.metadata = metadata;
        bytes memory hopDataBytes = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_SWAP_BRIDGE_SELECTOR(),
            513,
            swapImplData,
            hopData
        );

        deal(sender1, 1e8);
        deal(address(USDC), address(sender1), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(sender1), swapRequest.amount);
        IERC20(USDC).approve(address(socketGateway), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        uint256 gasStockbeforeSwap = gasleft();

        socketGateway.executeRoute(
            bridgeRouteId,
            hopDataBytes,
            abi.encode("SwapERC20-BridgeNative")
        );

        uint256 gasStockAfterSwap = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        console.log(
            "Swap-USDC on OneInch And Bridge-Native via Hop - GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
