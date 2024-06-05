// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";
import "../../../../src/bridges/polygon/interfaces/polygon.sol";

contract PolygonBridgeNativeTest is Test, SocketGatewayBaseTest {
    //ETH Mainnet
    address constant recipient = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant rootChainManagerProxy =
        0xA0c68C638235ee32657e8f720a23ceC1bFc77C77;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16333752);
        vm.selectFork(fork);
    }

    function testBridgeNative() public {
        uint256 amount = 20e18;

        vm.startPrank(caller);
        deal(caller, amount);
        assertEq(caller.balance, amount);
        vm.stopPrank();

        assertEq(recipient.balance, 0);

        vm.startPrank(caller);

        uint256 gasStockBeforeBridge = gasleft();

        IRootChainManager(rootChainManagerProxy).depositEtherFor{value: amount}(
            recipient
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(recipient.balance, 0);
        assertEq(caller.balance, 0);

        console.log(
            "Native-Polygon gas-cost for Direct-Bridge for Native: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
