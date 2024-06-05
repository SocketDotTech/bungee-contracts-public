// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";
import "../../../../../src/bridges/hop/interfaces/IHopL1Bridge.sol";

contract HopEthToArbitrumNativeTest is Test, SocketGatewayBaseTest {
    //ETH Mainnet
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15819486);
        vm.selectFork(fork);
    }

    function testDirectBridgeNative() public {
        address _l1bridgeAddr = 0xb8901acB165ed027E32754E0FFe830802919727f;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 0;
        uint256 _relayerFee = 0;
        uint256 _deadline = 0;

        uint256 amount = 1e18;

        deal(caller, amount);
        assertEq(caller.balance, amount);
        assertEq(recipient.balance, 0);

        vm.startPrank(caller);

        uint256 gasStockBeforeBridge = gasleft();

        IHopL1Bridge(_l1bridgeAddr).sendToL2{value: amount}(
            42161,
            recipient,
            amount,
            _amountOutMin,
            _deadline,
            _relayer,
            _relayerFee
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(caller.balance, 0);

        console.log(
            "HopL1-Direct-Bridge on Eth-Mainnet gas-cost for Native-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
