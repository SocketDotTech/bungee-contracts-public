// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";
import "../../../../../src/bridges/hop/interfaces/IHopL1Bridge.sol";

contract HopEthToArbitrumUSDCTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15819486);
        vm.selectFork(fork);
    }

    function testDirectBridgeUSDC() public {
        address _l1bridgeAddr = 0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 90e6;
        uint256 _relayerFee = 0;
        uint256 _deadline = block.timestamp + 100000;

        uint256 amount = 100e6;
        address token = USDC;

        deal(address(token), address(sender1), amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(recipient), 0);
        assertEq(IERC20(token).balanceOf(caller), 0);

        vm.startPrank(sender1);
        IERC20(token).approve(caller, amount);
        vm.stopPrank();

        vm.startPrank(caller);

        IERC20(token).safeTransferFrom(sender1, caller, amount);
        IERC20(token).safeIncreaseAllowance(_l1bridgeAddr, amount);

        uint256 gasStockBefore1stBridge = gasleft();

        // perform bridging
        IHopL1Bridge(_l1bridgeAddr).sendToL2(
            42161,
            recipient,
            amount,
            _amountOutMin,
            _deadline,
            _relayer,
            _relayerFee
        );

        uint256 gasStockAfter1stBridge = gasleft();

        assertEq(IERC20(token).balanceOf(caller), 0);
        assertEq(IERC20(token).balanceOf(sender1), 0);

        console.log(
            "Hop-Direct-Bridge USDC from Eth -> Arbitrum is: ",
            gasStockBefore1stBridge - gasStockAfter1stBridge
        );

        vm.stopPrank();
    }
}
