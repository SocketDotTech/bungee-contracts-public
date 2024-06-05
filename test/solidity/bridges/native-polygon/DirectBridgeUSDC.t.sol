// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";
import "../../../../src/bridges/polygon/interfaces/polygon.sol";

contract PolygonDirectBridgeUSDCTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    //Polygon Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant rootChainManagerProxy =
        0xA0c68C638235ee32657e8f720a23ceC1bFc77C77;
    address constant erc20PredicateProxy =
        0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16333752);
        vm.selectFork(fork);
    }

    function testBridgeUSDC() public {
        uint256 amount = 1000e6;
        address token = USDC;

        deal(address(USDC), sender1, amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);

        vm.startPrank(sender1);
        IERC20(USDC).approve(caller, amount);
        vm.stopPrank();

        assertEq(IERC20(USDC).balanceOf(caller), 0);

        vm.startPrank(caller);

        // set allowance for erc20 predicate
        IERC20(token).safeTransferFrom(sender1, caller, amount);
        IERC20(token).safeIncreaseAllowance(erc20PredicateProxy, amount);

        uint256 gasStockBeforeBridge = gasleft();

        // deposit into rootchain manager
        IRootChainManager(rootChainManagerProxy).depositFor(
            sender1,
            USDC,
            abi.encodePacked(amount)
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(IERC20(USDC).balanceOf(sender1), 0);

        console.log(
            "Native-Polygon gas-cost for Direct-USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
