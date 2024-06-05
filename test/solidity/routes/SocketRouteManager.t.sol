// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import "../../../lib/forge-std/src/console.sol";
import "../../../lib/forge-std/src/Script.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../SocketGatewayBaseTest.sol";
import {HopImplL1} from "../../../src/bridges/hop/l1/HopImplL1.sol";
import {HopImplL2} from "../../../src/bridges/hop/l2/HopImplL2.sol";
import {ISocketRoute} from "../../../src/interfaces/ISocketRoute.sol";
import {Address0Provided, OnlyOwner} from "../../../src/errors/SocketErrors.sol";

contract SocketRouteManagerTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    //ETH Mainnet
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    HopImplL1 internal hopImpl;
    HopImplL2 internal hopImplL2;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    event RouteDisabled(uint32 indexed routeID);

    function setUp() public {
        socketGateway = createSocketGateway();
        hopImpl = new HopImplL1(address(socketGateway), address(socketGateway));
        hopImplL2 = new HopImplL2(
            address(socketGateway),
            address(socketGateway)
        );
    }

    function testAddRoute() public {
        address route_0 = address(hopImpl);
        address route_1 = address(hopImplL2);

        // Emits Event
        emit NewRouteAdded(0, route_0);

        vm.startPrank(owner);
        socketGateway.addRoute(route_0);

        emit NewRouteAdded(1, route_1);
        socketGateway.addRoute(route_1);

        vm.stopPrank();

        address route = socketGateway.getRoute(513);
        assert(route == route_0);

        route = socketGateway.getRoute(514);
        assert(route == route_1);
    }

    function testDisableRoute() public {
        address route_0 = address(hopImpl);

        vm.startPrank(owner);
        socketGateway.addRoute(route_0);

        // Emits Event
        emit RouteDisabled(0);

        socketGateway.disableRoute(513);
        vm.stopPrank();

        address route = socketGateway.getRoute(513);
        assert(route == DISABLED_ROUTE);
    }

    function testRouteManagementByNonOwner() public {
        address route_0 = address(hopImpl);

        vm.startPrank(sender1);

        vm.expectRevert(OnlyOwner.selector);
        socketGateway.addRoute(route_0);

        vm.stopPrank();
    }
}
