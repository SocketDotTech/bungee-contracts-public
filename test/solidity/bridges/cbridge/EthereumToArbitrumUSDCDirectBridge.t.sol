// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../../src/bridges/cbridge/interfaces/cbridge.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";

contract CelerEthereumToBinanceUSDCTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    //Eth Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant CELER_BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    address constant WETH_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    ICBridge public router;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16227237);
        vm.selectFork(fork);
        router = ICBridge(CELER_BRIDGE);
    }

    function testBridgeUSDC() public {
        uint64 nonce = uint64(block.timestamp);
        uint32 maxSlippage = 5000;
        uint256 amount = 100e6;
        uint256 toChainId = 42161;

        deal(address(USDC), address(sender1), amount);

        vm.startPrank(sender1);
        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        IERC20(USDC).approve(caller, amount);
        vm.stopPrank();

        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        vm.startPrank(caller);

        IERC20(USDC).safeTransferFrom(sender1, caller, amount);
        IERC20(USDC).safeIncreaseAllowance(CELER_BRIDGE, amount);

        uint256 gasStockBeforeBridge = gasleft();

        router.send(
            receiver,
            USDC,
            amount,
            uint64(toChainId),
            nonce,
            maxSlippage
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(caller), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);
        assertEq(IERC20(USDC).balanceOf(sender1), 0);

        console.log(
            "Celer-Direct-Bridge gas cost for USDC-bridge to Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
