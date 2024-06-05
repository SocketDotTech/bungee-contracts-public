// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../../../src/bridges/stargate/interfaces/stargate.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";

contract StargateL2PolygonToOptimismUSDCDirectBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    using SafeERC20 for IERC20;

    //reference txn on Polygon for USDC bridging to EtherLite
    //https://polygonscan.com/tx/0x343a9b6cc9d4c7003811256873f6047a0c4399f09bb5ca15d5048e9bb229f4e0

    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant routerAddress = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    IBridgeStargate public router;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 37137945);
        vm.selectFork(fork);
        router = IBridgeStargate(routerAddress);
    }

    function testBridgeUSDC() public {
        uint256 srcPoolId = 1;
        uint256 dstPoolId = 1;
        uint256 minReceivedAmt = 290e6;
        uint16 stargateDstChainId = uint16(111);
        address senderAddress = sender1;
        bytes memory destinationPayload = EMPTY_DATA;

        uint256 amount = 300e6;
        uint256 value = 1e18;
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
        IERC20(token).safeIncreaseAllowance(address(routerAddress), amount);

        uint256 gasStockBeforeBridge = gasleft();

        {
            router.swap{value: value}(
                stargateDstChainId,
                srcPoolId,
                dstPoolId,
                payable(senderAddress), // default to refund to main contract
                amount,
                minReceivedAmt,
                IBridgeStargate.lzTxObj(0, 0, "0x"),
                abi.encodePacked(recipient),
                destinationPayload
            );
        }

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(token).balanceOf(sender1), 0);
        assertEq(IERC20(token).balanceOf(recipient), 0);
        assertEq(IERC20(token).balanceOf(caller), 0);

        console.log(
            "Stargate-L2-DirectBridge gas-cost for USDC-Direct-Bridging from Polygon-Mainnet to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
