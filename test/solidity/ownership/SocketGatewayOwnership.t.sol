// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import "../../../lib/forge-std/src/console.sol";
import "../../../lib/forge-std/src/Script.sol";
import "../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../SocketGatewayBaseTest.sol";
import {OnlyOwner, OnlyNominee} from "../../../src/errors/SocketErrors.sol";

contract RescueFundsAndNativeFromBridge is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    address private constant nominee =
        0x246Add954192f59396785f7195b8CB36841a9bE8;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    function setUp() public {
        socketGateway = createSocketGateway();
    }

    function testNominateOwner() public {
        vm.startPrank(owner);

        assertEq(socketGateway.nominee(), ZERO_ADDRESS);

        // Emits Event
        emit OwnerNominated(nominee);

        socketGateway.nominateOwner(nominee);

        assertEq(socketGateway.nominee(), nominee);

        vm.stopPrank();
    }

    function testNonOwnerCantNominate() public {
        vm.startPrank(nominee);

        assertEq(socketGateway.nominee(), ZERO_ADDRESS);

        // Emits Event
        vm.expectRevert(OnlyOwner.selector);

        socketGateway.nominateOwner(nominee);

        vm.stopPrank();
    }

    function testClaimAsOwner() public {
        vm.startPrank(owner);

        assertEq(socketGateway.nominee(), ZERO_ADDRESS);

        socketGateway.nominateOwner(nominee);
        assertEq(socketGateway.nominee(), nominee);
        vm.stopPrank();

        vm.startPrank(nominee);

        // Emits Event
        emit OwnerClaimed(nominee);

        socketGateway.claimOwner();

        assertEq(socketGateway.owner(), nominee);

        vm.stopPrank();
    }

    function testNonNomineeCantClaimAsOwner() public {
        vm.startPrank(owner);

        assertEq(socketGateway.nominee(), ZERO_ADDRESS);

        socketGateway.nominateOwner(nominee);
        assertEq(socketGateway.nominee(), nominee);

        vm.expectRevert(OnlyNominee.selector);
        socketGateway.claimOwner();

        vm.stopPrank();
    }
}
