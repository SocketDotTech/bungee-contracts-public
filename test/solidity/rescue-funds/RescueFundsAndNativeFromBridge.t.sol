// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import "../../../lib/forge-std/src/console.sol";
import "../../../lib/forge-std/src/Script.sol";
import "../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../SocketGatewayBaseTest.sol";
import {HopImplL2} from "../../../src/bridges/hop/l2/HopImplL2.sol";
import {OnlySocketGatewayOwner} from "../../../src/errors/SocketErrors.sol";

contract RescueFundsAndNativeFromBridge is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant treasury = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant hacker = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    HopImplL2 internal hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"));
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopImplL2(
            address(socketGateway),
            address(socketGateway)
        );
    }

    function testRescueFundsFromBridge() public {
        vm.startPrank(owner);
        deal(owner, 2e18);
        deal(address(hopBridgeImpl), 2e18);
        deal(USDC, address(hopBridgeImpl), 1000e6);
        assertEq(IERC20(USDC).balanceOf(address(hopBridgeImpl)), 1000e6);
        assertEq(IERC20(USDC).balanceOf(treasury), 0);

        hopBridgeImpl.rescueFunds(address(USDC), treasury, 1000e6);

        assertEq(IERC20(USDC).balanceOf(treasury), 1000e6);

        vm.stopPrank();
    }

    function testNonOwnerCantRescueFundsFromBridge() public {
        vm.startPrank(hacker);

        vm.expectRevert(OnlySocketGatewayOwner.selector);
        hopBridgeImpl.rescueFunds(address(USDC), treasury, 1000e6);

        vm.stopPrank();
    }

    function testRescueNativeFromBridge() public {
        vm.startPrank(owner);
        deal(owner, 1e16);
        deal(address(hopBridgeImpl), 2e18);

        assertEq(address(hopBridgeImpl).balance, 2e18);
        assertEq(treasury.balance, 0);

        hopBridgeImpl.rescueEther(payable(treasury), 2e18);

        assertEq(treasury.balance, 2e18);

        vm.stopPrank();
    }

    function testNonOwnerCantRescueNativeFromBridge() public {
        vm.startPrank(hacker);
        deal(hacker, 1e16);

        vm.expectRevert(OnlySocketGatewayOwner.selector);
        hopBridgeImpl.rescueEther(payable(treasury), 2e18);

        vm.stopPrank();
    }
}
