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

contract ScrollNativeBridgeEthTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    address constant sender1 = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
    uint256 amount = 500000000000000000;
    address constant receiver = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
    address constant _scrollL1GatewayRouter =
        0xF8B1378579659D8F7EE5f3C929c2f3E332E41Fd6;

    ScrollImpl internal baseBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 19345324);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        baseBridgeImpl = new ScrollImpl(
            address(_scrollL1GatewayRouter),
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(baseBridgeImpl);

        // Emits Event
        emit NewRouteAdded(0, address(baseBridgeImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testNativeBridging() public {
        vm.startPrank(sender1);
        uint256 gasLimit = 180000;
        uint256 fees = 100000000000000;
        uint32 toChainId = 54324;
        bytes32 bridgeHash = "scroll";
        // add initial amount to gateway
        deal(address(socketGateway), 10000000000000);
        deal(sender1, amount + fees);
        assertEq(sender1.balance, amount + fees);

        bytes memory impldata = abi.encodeWithSelector(
            baseBridgeImpl.SCROLL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            gasLimit,
            fees,
            metadata,
            amount,
            toChainId,
            bridgeHash
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount + fees}(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "Scroll Native Bridge native ETH from Ethereum Costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
