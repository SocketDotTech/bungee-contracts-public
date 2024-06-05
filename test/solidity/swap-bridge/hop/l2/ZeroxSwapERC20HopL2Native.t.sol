// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {ZeroXSwapImpl} from "../../../../../src/swap/zerox/ZeroXSwapImpl.sol";
import {HopImplL2} from "../../../../../src/bridges/hop/l2/HopImplL2.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../../src/interfaces/ISocketRequest.sol";

contract ZeroxSwapERC20HopL2NativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant zeroXExchangeProxy =
        0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    ZeroXSwapImpl internal zeroXSwapImpl;
    HopImplL2 internal hopBridgeImpl;

    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 37756484);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        zeroXSwapImpl = new ZeroXSwapImpl(
            zeroXExchangeProxy,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(zeroXSwapImpl);
        // Emits Event
        emit NewRouteAdded(0, route_0);

        socketGateway.addRoute(route_0);

        hopBridgeImpl = new HopImplL2(
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
        console.log("socketGateway", address(socketGateway));
        swapRequest.id = 513;
        swapRequest
            .receiverAddress = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
        swapRequest.amount = 1000000000;
        swapRequest.inputToken = USDC;
        swapRequest.toToken = NATIVE_TOKEN_ADDRESS;

        //https://polygon.api.0x.org/swap/v1/quote?buyToken=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&sellToken=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174&sellAmount=100000000&slippagePercentage=1&skipValidation=true
        bytes memory zeroxExtraData = bytes(
            hex"415565b00000000000000000000000002791bca1f2de4661ed88a30c99a7a9449aa84174000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000003b9aca00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000042000000000000000000000000000000000000000000000000000000000000004c0000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000360000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002791bca1f2de4661ed88a30c99a7a9449aa841740000000000000000000000000d500b1d8e8ef31e21c99d1db9a6444d3adf127000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000002e0000000000000000000000000000000000000000000000000000000003b9aca00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000012556e6973776170563300000000000000000000000000000000000000000000000000000000000000000000003b9aca000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000e592427a0aece92de3edee1f18e0157c05861564000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000422791bca1f2de4661ed88a30c99a7a9449aa84174000064c2132d05d31c914a87c6611c10748aeb04b58e8f0001f40d500b1d8e8ef31e21c99d1db9a6444d3adf12700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000d500b1d8e8ef31e21c99d1db9a6444d3adf1270ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000002791bca1f2de4661ed88a30c99a7a9449aa841740000000000000000000000000000000000000000000000000000000000000000869584cd000000000000000000000000100000000000000000000000000000000000001100000000000000000000000000000000000000000000002a12adca3563b88e24"
        );

        swapRequest.data = abi.encode(zeroxExtraData);

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory swapImplData = abi.encodeWithSelector(
            zeroXSwapImpl.SWAP_WITHIN_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.data
        );

        uint32 bridgeRouteId = 514;
        HopImplL2.HopBridgeDataNoToken memory hopData;
        hopData.receiverAddress = receiver;
        // hopData.token = NATIVE_TOKEN_ADDRESS;
        hopData.hopAMM = 0x884d1Aa15F9957E1aEAA86a82a72e49Bc2bfCbe3;
        hopData.toChainId = 1;
        hopData.bonderFee = 1000000000000000000;
        hopData.amountOutMin = 74293282923718320;
        hopData.deadline = block.timestamp + 100000;
        hopData.amountOutMinDestination = 74293282923718320;
        hopData.deadlineDestination = block.timestamp + 100000;
        hopData.metadata = metadata;
        bytes memory hopDataBytes = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L2_SWAP_BRIDGE_SELECTOR(),
            513,
            swapImplData,
            hopData
        );

        deal(address(USDC), address(sender1), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(sender1), swapRequest.amount);
        IERC20(USDC).approve(address(socketGateway), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(hopData.receiverAddress), 0);

        uint256 gasStockbeforeSwap = gasleft();

        socketGateway.executeRoute(
            bridgeRouteId,
            hopDataBytes,
            abi.encode("SwapERC20-BridgeNative")
        );

        uint256 gasStockAfterSwap = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(hopData.receiverAddress), 0);

        console.log(
            "Swap-USDC on Zerox And Bridge-Native via HopL2 - GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
