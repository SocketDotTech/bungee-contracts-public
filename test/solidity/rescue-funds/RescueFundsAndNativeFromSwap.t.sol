// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import "../../../lib/forge-std/src/console.sol";
import "../../../lib/forge-std/src/Script.sol";
import "../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../SocketGatewayBaseTest.sol";
import {OneInchImpl} from "../../../src/swap/oneinch/OneInchImpl.sol";
import {OnlySocketGatewayOwner} from "../../../src/errors/SocketErrors.sol";

contract RescueFundsAndNativeFromSwap is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant treasury = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant hacker = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    OneInchImpl internal oneInchImpl;
    address oneInchImplAddress;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"));
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        oneInchImpl = new OneInchImpl(
            0x1111111254EEB25477B68fb85Ed929f73A960582,
            address(socketGateway),
            address(socketGateway)
        );
        oneInchImplAddress = address(oneInchImpl);
    }

    function testRescueFundsFromSwap() public {
        vm.startPrank(owner);
        deal(owner, 2e18);
        deal(address(oneInchImpl), 2e18);
        deal(USDC, address(oneInchImpl), 1000e6);
        assertEq(IERC20(USDC).balanceOf(address(oneInchImpl)), 1000e6);
        assertEq(IERC20(USDC).balanceOf(treasury), 0);

        oneInchImpl.rescueFunds(address(USDC), treasury, 1000e6);

        assertEq(IERC20(USDC).balanceOf(treasury), 1000e6);

        vm.stopPrank();
    }

    function testNonOwnerCantRescueFundsFromSwap() public {
        vm.startPrank(hacker);

        vm.expectRevert(OnlySocketGatewayOwner.selector);
        oneInchImpl.rescueFunds(address(USDC), treasury, 1000e6);

        vm.stopPrank();
    }

    function testRescueNativeFromSwap() public {
        vm.startPrank(owner);
        deal(owner, 1e16);
        deal(address(oneInchImpl), 2e18);

        assertEq(address(oneInchImpl).balance, 2e18);
        assertEq(treasury.balance, 0);

        oneInchImpl.rescueEther(payable(treasury), 2e18);

        assertEq(treasury.balance, 2e18);

        vm.stopPrank();
    }

    function testNonOwnerCantRescueNativeFromSwap() public {
        vm.startPrank(hacker);
        deal(hacker, 1e16);

        vm.expectRevert(OnlySocketGatewayOwner.selector);
        oneInchImpl.rescueEther(payable(treasury), 2e18);

        vm.stopPrank();
    }
}
