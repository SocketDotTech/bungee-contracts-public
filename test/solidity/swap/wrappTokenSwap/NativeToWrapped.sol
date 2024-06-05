// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "forge-std/console.sol";
import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {WrappedTokenSwapperImpl} from "../../../../src/swap/wrappedTokenSwapper/swapWrappedImpl.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";

contract WrappedTokenToNativeTest is Test, SocketGatewayBaseTest {
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

    address constant sender1 = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
    address constant WRAPPED_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    WrappedTokenSwapperImpl internal wrappedTokenSwapperImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 52194277);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        wrappedTokenSwapperImpl = new WrappedTokenSwapperImpl(
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(wrappedTokenSwapperImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);

        socketGateway.addRoute(route_0);

        vm.stopPrank();
    }

    // swap 100 WRAPPED_TOKEN -> ETH
    function testSwapWrappedTokenToNative() public {
        address receiverAddress = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
        uint256 amount = 1000;
        address inputToken = NATIVE_TOKEN_ADDRESS;
        address toToken = WRAPPED_TOKEN;

        bytes memory withdrawData = abi.encodeWithSelector(
            bytes4(keccak256("deposit()"))
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            wrappedTokenSwapperImpl.SWAP_FUNCTION_SELECTOR(),
            inputToken,
            toToken,
            amount,
            receiverAddress,
            metadata,
            withdrawData
        );

        deal(address(WRAPPED_TOKEN), address(sender1), amount);
        deal(address(WRAPPED_TOKEN), address(socketGateway), amount);

        assertEq(IERC20(WRAPPED_TOKEN).balanceOf(sender1), amount);

        console.log(IERC20(WRAPPED_TOKEN).balanceOf(sender1), amount);

        vm.startPrank(sender1);
        IERC20(WRAPPED_TOKEN).approve(address(socketGateway), amount);
        socketGateway.executeRoute{value: amount}(385, impldata);

        uint256 gasStockbeforeSwap = gasleft();

        uint256 gasStockAfterSwap = gasleft();

        console.log(
            "Zerox-Swap ERC20 to Native -> GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
