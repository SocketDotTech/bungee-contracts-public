// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";
import {HopAMM} from "../../../../../src/bridges/hop/interfaces/amm.sol";

contract HopPolygonToArbitrumUSDCTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 37663689);
        vm.selectFork(fork);
    }

    function testDirectBridgeUSDC() public {
        address _hopAMM = 0x76b22b8C1079A44F1211D867D68b1eda76a635A7;
        // fees passed to relayer
        uint256 _bonderFee = 200000;
        uint256 _amountOutMin = 240e6;
        uint256 _deadline = block.timestamp + 100000;
        uint256 _amountOutMinDestination = 240e6;
        uint256 _deadlineDestination = block.timestamp + 100000;

        uint256 amount = 250e6;
        uint256 toChainId = 42161;

        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        vm.startPrank(sender1);
        IERC20(USDC).approve(caller, amount);
        vm.stopPrank();

        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        vm.startPrank(caller);

        IERC20(USDC).safeTransferFrom(sender1, caller, amount);
        IERC20(USDC).safeIncreaseAllowance(_hopAMM, amount);

        uint256 gasStockBeforeBridge = gasleft();

        HopAMM(_hopAMM).swapAndSend(
            toChainId,
            receiver,
            amount,
            _bonderFee,
            _amountOutMin,
            _deadline,
            _amountOutMinDestination,
            _deadlineDestination
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        console.log(
            "HopL2DirectBridge - gas cost for USDC-bridge on Polygon: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
