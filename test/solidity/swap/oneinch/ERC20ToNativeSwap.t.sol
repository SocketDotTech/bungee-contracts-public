// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {OneInchImpl} from "../../../../src/swap/oneinch/OneInchImpl.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";

//Swap the ERC20 to Native with SocketGateway itself as a receiverAddress
// this is equivalent to `performAction` in aggregator-contracts
contract One_InchERC20ToNativeSwapTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    address public immutable ONEINCH_AGGREGATOR =
        0x1111111254EEB25477B68fb85Ed929f73A960582;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //ETH Mainnet
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    OneInchImpl internal OneInch;

    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

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

        vm.stopPrank();
    }

    // swap 100 USDC -> ETH
    function testSwapERC20ToNative() public {
        SwapRequest memory swapRequest;

        swapRequest.id = 0;
        swapRequest.receiverAddress = recipient;
        swapRequest.amount = 100e6;
        swapRequest.inputToken = USDC;
        swapRequest.toToken = NATIVE_TOKEN_ADDRESS;
        bytes memory eventData = abi.encodePacked(
            "oneinch",
            "erc20-native",
            "swap"
        );

        //https://api.1inch.io/v5.0/1/swap?fromTokenAddress=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&toTokenAddress=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&amount=100000000&fromAddress=0x2e234DAe75C793f67A35089C9d99245E1C58470b&slippage=1&destReceiver=0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba&disableEstimate=true
        swapRequest.data = bytes(
            hex"f78dc253000000000000000000000000cd4faec53142e37f657d7b44504de8ed13af40ba000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000125e946077e6d1200000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000140000000000000003b6d0340b4e16d0168e52d35cacd2c6185b44281ec28c9dccfee7c08"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            OneInch.SWAP_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.receiverAddress,
            swapRequest.data
        );

        deal(address(USDC), address(sender1), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(sender1), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(address(socketGateway).balance, 0);
        uint256 receiver_NativeBalance_BefSwap = swapRequest
            .receiverAddress
            .balance;

        vm.startPrank(sender1);

        IERC20(USDC).approve(address(socketGateway), swapRequest.amount);

        // Emits Event
        uint256 expected_Swapped_Amount = 84293282923718320;
        emit SocketSwapTokens(
            swapRequest.inputToken,
            swapRequest.toToken,
            expected_Swapped_Amount,
            swapRequest.amount,
            ONEINCH,
            swapRequest.receiverAddress
        );

        uint256 gasStockbeforeSwap = gasleft();
        bytes memory swapResponseData = socketGateway.executeRoute(
            513,
            impldata,
            eventData
        );
        uint256 gasStockAfterSwap = gasleft();

        uint256 swappedAmount = abi.decode(swapResponseData, (uint256));

        assertEq(IERC20(USDC).balanceOf(sender1), 0);

        uint256 receiver_NativeBalance_AftSwap = swapRequest
            .receiverAddress
            .balance;
        assertEq(
            receiver_NativeBalance_AftSwap - receiver_NativeBalance_BefSwap,
            swappedAmount
        );
        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "OneInch-Swap ERC20 to Native -> GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
