// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import "../../../lib/forge-std/src/console.sol";
import "../../../lib/forge-std/src/Script.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../SocketGatewayBaseTest.sol";
import {ISocketController} from "../../../src/interfaces/ISocketController.sol";
import {RefuelSwapAndBridgeController} from "../../../src/controllers/RefuelSwapAndBridgeController.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../src/errors/SocketErrors.sol";

contract ControllerManagerTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant stranger = 0x246Add954192f59396785f7195b8CB36841a9bE8;

    function setUp() public {
        socketGateway = createSocketGateway();
    }

    /**
     * Test Behavior: AddController call should end up adding controller to the mapping of SocketGatewayStorage
     */
    function testAddController() public {
        RefuelSwapAndBridgeController refuelSwapAndBridgeController = new RefuelSwapAndBridgeController(
                address(socketGateway)
            );
        vm.startPrank(owner);
        socketGateway.addController(address(refuelSwapAndBridgeController));

        address controller = socketGateway.getController(0);
        assertEq(controller, address(refuelSwapAndBridgeController));

        vm.stopPrank();
    }

    /**
     * Test Behavior: DisableController call should end up disabling controller in the mapping of SocketGatewayStorage
     */
    function testDisableController() public {
        RefuelSwapAndBridgeController refuelSwapAndBridgeController = new RefuelSwapAndBridgeController(
                address(socketGateway)
            );
        vm.startPrank(owner);
        socketGateway.addController(address(refuelSwapAndBridgeController));
        address controller = socketGateway.getController(0);

        socketGateway.disableController(0);

        controller = socketGateway.getController(0);
        assertEq(controller, address(0));

        vm.stopPrank();
    }

    /**
     * Test Behavior: NonOwner should be stopped from adding controller to the mapping of SocketGatewayStorage
     */
    function testNonOwnerCantAddController() public {
        RefuelSwapAndBridgeController refuelSwapAndBridgeController = new RefuelSwapAndBridgeController(
                address(socketGateway)
            );

        vm.startPrank(stranger);
        vm.expectRevert(OnlyOwner.selector);
        socketGateway.addController(address(refuelSwapAndBridgeController));
        vm.stopPrank();
    }
}
