// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../src/bridges/hyphen/interfaces/hyphen.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";

contract HyphenEthToFantomUSDCDirectBridgeTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant liquidityPoolManagerAddress =
        0x2A5c2568b10A0E826BfA892Cf21BA7218310180b;
    string constant tag = "SOCKET";
    HyphenLiquidityPoolManager public liquidityPoolManager;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15819486);
        vm.selectFork(fork);
        liquidityPoolManager = HyphenLiquidityPoolManager(
            liquidityPoolManagerAddress
        );
    }

    function testSendUSDCToFantom() public {
        uint256 amount = 100e6;
        uint256 toChainId = 42161;

        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        vm.startPrank(sender1);
        IERC20(USDC).approve(caller, amount);
        vm.stopPrank();

        vm.startPrank(caller);

        IERC20(USDC).safeTransferFrom(sender1, caller, amount);
        IERC20(USDC).safeIncreaseAllowance(liquidityPoolManagerAddress, amount);

        uint256 gasStockBeforeBridge = gasleft();

        liquidityPoolManager.depositErc20(
            toChainId,
            USDC,
            receiver,
            amount,
            tag
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        console.log(
            "Hyphen-Direct-Bridge USDC from Ethereum to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
