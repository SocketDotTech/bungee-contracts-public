// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {ZeroXSwapImpl} from "../../../../src/swap/zerox/ZeroXSwapImpl.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";

contract ERC20ToNativeSwapWithInTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }
    //ETH Mainnet

    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant zeroXExchangeProxy =
        0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    ZeroXSwapImpl internal zeroXSwapImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16219787);
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

        vm.stopPrank();
    }

    // swap 100 USDC -> ETH
    function testSwapWithInERC20ToNative() public {
        SwapRequest memory swapRequest;

        swapRequest.id = 513;
        swapRequest.receiverAddress = address(socketGateway);
        swapRequest.amount = 100e6;
        swapRequest.inputToken = USDC;
        swapRequest.toToken = NATIVE_TOKEN_ADDRESS;
        bytes memory eventData = abi.encodePacked(
            "zerox",
            "erc20-native",
            "swapWithIn"
        );

        //https://api.0x.org/swap/v1/quote?buyToken=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&sellToken=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&sellAmount=100000000&slippagePercentage=1&skipValidation=true
        bytes memory zeroxExtraData = bytes(
            hex"d9627aa400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000005f5e100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee869584cd00000000000000000000000010000000000000000000000000000000000000110000000000000000000000000000000000000000000000dbebd15bbe63a4a0ae"
        );

        swapRequest.data = abi.encode(zeroxExtraData);

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            zeroXSwapImpl.SWAP_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.receiverAddress,
            swapRequest.data
        );

        deal(address(USDC), address(sender1), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(sender1), swapRequest.amount);

        uint256 receiverNativeBalance_BeforeSwap = address(socketGateway)
            .balance;

        vm.startPrank(sender1);

        deal(address(USDC), address(sender1), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(sender1), swapRequest.amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        IERC20(USDC).approve(address(socketGateway), swapRequest.amount);

        uint256 gasStockbeforeSwap = gasleft();

        bytes memory swapResponseData = socketGateway.executeRoute(
            513,
            impldata,
            eventData
        );

        uint256 gasStockAfterSwap = gasleft();

        uint256 swappedAmount = abi.decode(swapResponseData, (uint256));

        uint256 receiverNativeBalance_AfterSwap = address(socketGateway)
            .balance;

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(
            receiverNativeBalance_AfterSwap - receiverNativeBalance_BeforeSwap,
            swappedAmount
        );

        console.log(
            "Zerox-Swap-WithIn ERC20 to Native -> GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
