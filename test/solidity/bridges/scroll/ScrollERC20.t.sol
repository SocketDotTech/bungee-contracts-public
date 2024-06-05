// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {ScrollImpl} from "../../../../src/bridges/scroll/ScrollBridgeImpl.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract ScrollNativeBridgeUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;

    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address scrollL1GatewayRouter = 0xF8B1378579659D8F7EE5f3C929c2f3E332E41Fd6;
    ScrollImpl internal scrollImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 19226413);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        scrollImpl = new ScrollImpl(
            address(scrollL1GatewayRouter),
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(scrollImpl);

        // Emits Event
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testSendUSDCOnL1BridgeRequest() public {
        address token = USDC;
        uint256 bridgingAmount = 3000000000;
        uint32 gasLimit = 1700000;
        uint256 fees = 1000000000000000;
        bytes32 bridgeHash = "scroll";
        uint32 toChainId = 1;

        bytes memory impldata = abi.encodeWithSelector(
            scrollImpl.SCROLL_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            token,
            sender1,
            gasLimit,
            fees,
            metadata,
            bridgingAmount,
            toChainId,
            bridgeHash
        );

        deal(address(token), address(sender1), bridgingAmount);
        // add initial amount to gateway
        deal(address(socketGateway), 1000000000000000);
        deal(sender1, fees);
        assertEq(IERC20(token).balanceOf(sender1), bridgingAmount);

        vm.startPrank(sender1);

        IERC20(token).approve(address(socketGateway), bridgingAmount);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: fees}(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "Scroll native Bridge on Eth-Mainnet gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
