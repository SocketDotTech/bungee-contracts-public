// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../src/bridges/cbridge/interfaces/cbridge.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";

contract CelerEthereumToArbitrumNativeTest is Test, SocketGatewayBaseTest {
    // Mainnet
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant CELER_BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    address constant WETH_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    ICBridge public router;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16227237);
        vm.selectFork(fork);
        router = ICBridge(CELER_BRIDGE);
    }

    function testBridgeNative() public {
        uint64 nonce = uint64(block.timestamp);
        uint32 maxSlippage = 5000;

        uint256 amount = 1e18;
        uint256 toChainId = 42161;

        deal(caller, amount);
        assertEq(caller.balance, amount);
        assertEq(receiver.balance, 0);

        vm.startPrank(caller);

        uint256 gasStockBeforeBridge = gasleft();

        router.sendNative{value: amount}(
            receiver,
            amount,
            uint64(toChainId),
            nonce,
            maxSlippage
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(caller.balance, 0);
        assertEq(receiver.balance, 0);

        console.log(
            "Celer-DirectBridge - gas cost for Native-bridge to Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
