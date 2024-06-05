// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../src/bridges/hyphen/interfaces/hyphen.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";

contract HyphenEthToFantomNativeTest is Test, SocketGatewayBaseTest {
    //ETH Mainnet
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
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

    function testBridgeNative() public {
        uint256 amount = 1e18;
        uint256 toChainId = 42161;

        deal(caller, amount);
        assertEq(caller.balance, amount);
        assertEq(recipient.balance, 0);

        vm.startPrank(caller);

        uint256 gasStockBeforeBridge = gasleft();

        liquidityPoolManager.depositNative{value: amount}(
            recipient,
            toChainId,
            tag
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(caller.balance, 0);
        assertEq(recipient.balance, 0);

        console.log(
            "Hyphen-Direct-Bridge NativeToken from Ethereum to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
