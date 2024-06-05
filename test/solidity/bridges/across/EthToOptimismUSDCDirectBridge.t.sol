// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../../src/bridges/across/interfaces/across.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";

contract EthToOptimismUSDCDirectBridgeTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
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

    function testDirectBridgeUSDC() public {
        int64 _relayerFeePct = 0;
        uint32 _quoteTimestamp = uint32(block.timestamp);

        uint256 amount = 100e6;
        address token = USDC;
        uint256 toChainId = 10;

        deal(token, sender1, amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(recipient), 0);
        assertEq(IERC20(token).balanceOf(caller), 0);

        vm.startPrank(sender1);
        IERC20(token).approve(caller, amount);
        vm.stopPrank();

        vm.startPrank(caller);

        IERC20(token).safeTransferFrom(sender1, caller, amount);
        IERC20(token).safeIncreaseAllowance(spokePoolAddress, amount);

        uint256 gasStockBeforeBridge = gasleft();

        spokePool.deposit(
            recipient,
            token,
            amount,
            toChainId,
            _relayerFeePct,
            _quoteTimestamp,
            "",
            type(uint256).max
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(token).balanceOf(caller), 0);
        assertEq(IERC20(token).balanceOf(sender1), 0);
        assertEq(IERC20(token).balanceOf(recipient), 0);

        console.log(
            "Across-Direct-Bridge gas-cost to bridge USDC ETH to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
