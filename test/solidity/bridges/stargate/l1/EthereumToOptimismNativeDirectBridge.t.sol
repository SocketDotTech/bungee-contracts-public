// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IBridgeStargate} from "../../../../../src/bridges/stargate/interfaces/stargate.sol";
import {StargateImplL1} from "../../../../../src/bridges/stargate/l1/Stargate.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";

contract StargateL1EthereumToOptimismNativeDirectBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    //ETH Mainnet to Ethereum-Lite reference transaction
    //https://etherscan.io/tx/0x7d23443e36f95f411e89002cc28497be5a0447a39765317ded4fe7d51a290629

    address constant routerETHAddress =
        0x150f94B44927F078737562f0fcF3C95c01Cc2376;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    IBridgeStargate public routerETH;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15588208);
        vm.selectFork(fork);
        routerETH = IBridgeStargate(routerETHAddress);
    }

    function testBridgeNative() public {
        uint256 minReceivedAmt = 1e16;
        uint256 optionalValue = 1e16;
        uint16 stargateDstChainId = 111;
        address senderAddress = caller;

        uint256 amount = 1e18;

        deal(caller, amount + optionalValue);
        assertEq(caller.balance, amount + optionalValue);
        assertEq(recipient.balance, 0);

        vm.startPrank(caller);

        uint256 gasStockBeforeBridge = gasleft();

        // perform bridging
        routerETH.swapETH{value: amount + optionalValue}(
            stargateDstChainId,
            payable(senderAddress),
            abi.encodePacked(recipient),
            amount,
            minReceivedAmt
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(recipient.balance, 0);

        console.log(
            "Stargate-L1-DirectBridge gas-cost for Native Bridging to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
