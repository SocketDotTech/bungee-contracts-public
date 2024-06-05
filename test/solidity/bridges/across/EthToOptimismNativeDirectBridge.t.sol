// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../src/bridges/across/interfaces/across.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";

contract EthToOptimismNativeTest is Test, SocketGatewayBaseTest {
    //ETH Mainnet
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant spokePoolAddress =
        0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    SpokePool public spokePool;

    function setUp() public {
        //https://etherscan.io/tx/0x2335e1ed11fb5d179283f133dfaa9e51c5bf998b8b4cc84f357c18588c41db4a
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15819486);
        vm.selectFork(fork);
        spokePool = SpokePool(spokePoolAddress);
    }

    function testBridgeNative() public {
        uint64 _relayerFeePct = 0;
        uint32 _quoteTimestamp = uint32(block.timestamp);
        uint256 amount = 1e18;
        uint256 toChainId = 10;

        deal(caller, amount);
        assertEq(caller.balance, amount);
        assertEq(recipient.balance, 0);

        uint256 gasStockBeforeBridge = gasleft();

        vm.startPrank(caller);

        spokePool.deposit{value: amount}(
            recipient,
            WETH,
            amount,
            toChainId,
            int64(_relayerFeePct),
            _quoteTimestamp,
            "",
            type(uint256).max
        );

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "Across-Direct-Bridge gas-cost to bridge Native from ETH to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
