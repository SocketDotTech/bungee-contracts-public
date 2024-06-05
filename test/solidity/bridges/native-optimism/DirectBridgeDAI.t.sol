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
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant optDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    bytes32 constant zeroBytes32 =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant synthCurrencyKey =
        0x7355534400000000000000000000000000000000000000000000000000000000;

    address constant customDAIBridge =
        0x10E6593CDda8c58a1d0f14C5164B376352a55f2F;
    address constant customSnxBridge =
        0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F;
    address constant customSynthAddress =
        0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F;
    uint256 constant newInterfaceId = 1;
    uint256 constant oldInterfaceId = 2;
    uint256 constant synthInterfaceId = 3;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15876510);
        vm.selectFork(fork);
    }

    function testSendUSDCOnL1BridgeRequest() public {
        address _l2Token = optDAI;
        uint32 _l2Gas = 2000000;
        bytes memory _data = "0x";
        address _customBridgeAddress = customDAIBridge;
        address _token = DAI;

        uint256 bridgeAmount = 1000e18;

        deal(address(_token), address(sender1), bridgeAmount);
        assertEq(IERC20(_token).balanceOf(sender1), bridgeAmount);
        assertEq(IERC20(_token).balanceOf(caller), 0);

        vm.startPrank(sender1);
        IERC20(_token).approve(caller, bridgeAmount);
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
            "NativeOptimism DirectBridge DAI: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        assertEq(IERC20(_token).balanceOf(sender1), 0);
        assertEq(IERC20(_token).balanceOf(caller), 0);

        vm.stopPrank();
    }
}
