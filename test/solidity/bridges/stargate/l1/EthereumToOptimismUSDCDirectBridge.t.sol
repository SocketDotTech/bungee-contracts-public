// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {StargateImplL1} from "../../../../../src/bridges/stargate/l1/Stargate.sol";
import {IBridgeStargate} from "../../../../../src/bridges/stargate/interfaces/stargate.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";

contract StargateL1EthereumToOptimismUSDCTest is Test, SocketGatewayBaseTest {
    using SafeERC20 for IERC20;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant routerAddress = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    IBridgeStargate public router;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15588208);
        vm.selectFork(fork);
        router = IBridgeStargate(routerAddress);
    }

    struct StargateTestLocalVars {
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt;
        uint256 destinationGasLimit;
        address receiver;
        bytes destinationPayload;
        uint16 stargateDstChainId;
    }

    function testBridgeUSDC() public {
        address senderAddress = sender1;
        uint256 amount = 300e6;
        uint256 value = 1e16;
        address token = USDC;

        deal(address(token), address(sender1), amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(recipient), 0);
        assertEq(IERC20(token).balanceOf(caller), 0);

        deal(caller, value);

        vm.startPrank(sender1);
        IERC20(token).approve(caller, amount);
        vm.stopPrank();

        vm.startPrank(caller);

        IERC20(token).safeTransferFrom(sender1, caller, amount);
        IERC20(token).safeIncreaseAllowance(routerAddress, amount);

        uint256 gasStockBeforeBridge = gasleft();

        StargateTestLocalVars memory stargateTestLocalVars;
        stargateTestLocalVars.srcPoolId = 1;
        stargateTestLocalVars.dstPoolId = 1;
        stargateTestLocalVars.stargateDstChainId = 111;
        stargateTestLocalVars.destinationGasLimit = 0;
        stargateTestLocalVars.destinationPayload = EMPTY_DATA;
        stargateTestLocalVars.minReceivedAmt = 290e6;

        {
            router.swap{value: value}(
                stargateTestLocalVars.stargateDstChainId,
                stargateTestLocalVars.srcPoolId,
                stargateTestLocalVars.dstPoolId,
                payable(senderAddress), // default to refund to main contract
                amount,
                stargateTestLocalVars.minReceivedAmt,
                IBridgeStargate.lzTxObj(
                    stargateTestLocalVars.destinationGasLimit,
                    0,
                    "0x"
                ),
                abi.encodePacked(recipient),
                stargateTestLocalVars.destinationPayload
            );
        }

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(token).balanceOf(sender1), 0);
        assertEq(IERC20(token).balanceOf(recipient), 0);
        assertEq(IERC20(token).balanceOf(caller), 0);

        console.log(
            "Stargate-L1-Direct-Bridge -> gas-cost for USDC-bridge from Eth-> Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
