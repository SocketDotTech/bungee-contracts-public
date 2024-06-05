// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";
import {L1GatewayRouter} from "../../../../src/bridges/arbitrum/interfaces/arbitrum.sol";

contract ArbitrumDirectBridgeUSDCTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant nativeArbitrumRouterAddress =
        0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16333752);
        vm.selectFork(fork);
    }

    function testDirectBridgeUSDC() public {
        address gatewayAddress = 0xcEe284F754E854890e311e3280b767F80797180d;
        uint256 maxGas = 357500;
        uint256 gasPriceBid = 300000000;
        bytes
            memory data = hex"000000000000000000000000000000000000000000000000000097d65f01cc4000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000";

        uint256 bridgeAmount = 1000e6;
        uint256 bridgeValue = 274196972748864;

        deal(caller, bridgeValue);
        assertEq(caller.balance, bridgeValue);
        deal(address(USDC), address(sender1), bridgeAmount);
        assertEq(IERC20(USDC).balanceOf(sender1), bridgeAmount);
        assertEq(IERC20(USDC).balanceOf(caller), 0);

        vm.startPrank(sender1);
        IERC20(USDC).approve(caller, bridgeAmount);
        vm.stopPrank();

        vm.startPrank(caller);

        IERC20(USDC).safeTransferFrom(sender1, caller, bridgeAmount);
        IERC20(USDC).safeIncreaseAllowance(gatewayAddress, bridgeAmount);

        uint256 gasStockBefore = gasleft();

        L1GatewayRouter(nativeArbitrumRouterAddress).outboundTransfer{
            value: bridgeValue
        }(USDC, sender1, bridgeAmount, maxGas, gasPriceBid, data);

        uint256 gasStockAfter = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(caller.balance, 0);
        assertEq(sender1.balance, 0);

        vm.stopPrank();

        console.log(
            "NativeArbitrum gasCost for Direct-USDC-bridge: ",
            gasStockBefore - gasStockAfter
        );
    }
}
