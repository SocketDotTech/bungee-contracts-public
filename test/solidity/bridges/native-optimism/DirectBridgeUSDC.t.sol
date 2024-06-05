// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {L1StandardBridge} from "../../../../src/bridges/optimism/interfaces/optimism.sol";
import {SocketGatewayBaseTest} from "../../SocketGatewayBaseTest.sol";

contract OptimismDirectBridgeUSDCTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant optSNX = 0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4;
    address constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address constant sUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address constant optSusd = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;
    address constant optUSDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    bytes32 constant zeroBytes32 =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant synthCurrencyKey =
        0x7355534400000000000000000000000000000000000000000000000000000000;

    address constant customUSDCBridge =
        0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address constant customSnxBridge =
        0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F;
    address constant customSynthAddress =
        0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F;
    uint256 constant newInterfaceId = 1;
    uint256 constant oldInterfaceId = 2;
    uint256 constant synthInterfaceId = 3;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"));
        vm.selectFork(fork);
    }

    function testSendUSDCOnL1BridgeRequest() public {
        address _l2Token = optUSDC;
        uint32 _l2Gas = 2000000;
        bytes memory _data = "0x";
        address _customBridgeAddress = customUSDCBridge;
        address _token = USDC;

        uint256 bridgeAmount = 1000e6;

        deal(address(USDC), address(sender1), bridgeAmount);
        assertEq(IERC20(USDC).balanceOf(sender1), bridgeAmount);
        assertEq(IERC20(USDC).balanceOf(caller), 0);

        vm.startPrank(sender1);
        IERC20(USDC).approve(caller, bridgeAmount);
        vm.stopPrank();

        vm.startPrank(caller);

        IERC20(_token).safeTransferFrom(sender1, caller, bridgeAmount);
        IERC20(_token).safeIncreaseAllowance(
            _customBridgeAddress,
            bridgeAmount
        );

        uint256 gasStockBeforeBridge = gasleft();

        // deposit into standard bridge
        L1StandardBridge(_customBridgeAddress).depositERC20To(
            _token,
            _l2Token,
            sender1,
            bridgeAmount,
            _l2Gas,
            _data
        );

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "NativeOptimism DirectBridge USDC: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(caller), 0);

        vm.stopPrank();
    }
}
