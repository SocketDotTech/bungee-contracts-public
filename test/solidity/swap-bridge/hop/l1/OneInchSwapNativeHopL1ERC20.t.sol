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

contract OneInchSwapNativeHopL1ERC20Test is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    address public immutable ONEINCH_AGGREGATOR =
        0x1111111254EEB25477B68fb85Ed929f73A960582;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }
    //ETH Mainnet
    // whale address

    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    OneInchImpl internal OneInch;
    HopImplL1 internal hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16257266);
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
        swapRequest.amount = 10000000000000000;
        swapRequest.inputToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        swapRequest.toToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        swapRequest.data = bytes(
            hex"0502b1c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000b82bc10000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340397ff1542f962076d0bfe58ea045ffa2d347aca0cfee7c08"
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
        HopImplL1.HopDataNoToken memory hopExtraData;
        hopExtraData.receiverAddress = sender1;
        // hopExtraData.token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        hopExtraData.toChainId = 42161;
        hopExtraData.l1bridgeAddr = 0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
        hopExtraData.relayer = 0x0000000000000000000000000000000000000000;
        hopExtraData.amountOutMin = 290e6;
        hopExtraData.relayerFee = 0;
        hopExtraData.deadline = block.timestamp + 100000;
        hopExtraData.metadata = metadata;
        bytes memory hopDataBytes = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_SWAP_BRIDGE_SELECTOR(),
            513,
            swapImplData,
            hopExtraData
        );

        deal(sender1, swapRequest.amount + 1e8);

        uint256 gasStockBeforeSwapAndBridge = gasleft();

        socketGateway.executeRoute{value: swapRequest.amount}(
            bridgeRouteId,
            hopDataBytes,
            abi.encode("SwapNative-BridgeERC20")
        );

        uint256 gasStockAfterSwapAndBridge = gasleft();

        console.log(
            "SwapAndBridge Through Socket gateway -> GasUsed:  ",
            gasStockBeforeSwapAndBridge - gasStockAfterSwapAndBridge
        );

        vm.stopPrank();
    }
}
