// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {OneInchImpl} from "../../../../src/swap/oneinch/OneInchImpl.sol";
import {AcrossImpl} from "../../../../src/bridges/across/Across.sol";
import {HopImplL1} from "../../../../src/bridges/hop/l1/HopImplL1.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";

contract SwapNativeAndERC20MultiBridgeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    struct TestLocalVars {
        bytes swapImplData;
        uint32[] bridgeRouteIds;
        bytes[] bridgeDataItems;
        uint256[] bridgeRatios;
        bytes[] eventDataItems;
    }

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant sender = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant recipient1 = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant recipient2 = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant spokePoolAddress =
        0x4D9079Bb4165aeb4084c526a32695dCfd2F77381;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable ONEINCH_AGGREGATOR =
        0x1111111254EEB25477B68fb85Ed929f73A960582;

    OneInchImpl internal OneInch;
    AcrossImpl internal acrossImpl;
    HopImplL1 internal hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16257266);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        OneInch = new OneInchImpl(
            ONEINCH_AGGREGATOR,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(OneInch);
        // Emits Event
        emit NewRouteAdded(0, route_0);

        socketGateway.addRoute(route_0);

        acrossImpl = new AcrossImpl(
            spokePoolAddress,
            WETH,
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(acrossImpl);
        socketGateway.addRoute(route_1);

        hopBridgeImpl = new HopImplL1(
            address(socketGateway),
            address(socketGateway)
        );
        address route_2 = address(hopBridgeImpl);
        socketGateway.addRoute(route_2);

        vm.stopPrank();
    }

    // Something related to forge is causing the one inch contract not to be deployed
    function testSwapNativeAndERC20MultiBridge() public {
        vm.startPrank(sender);

        SwapRequest memory swapRequest;

        swapRequest.id = 513;
        swapRequest
            .receiverAddress = 0x8657AB84A5B7Fc75B9327d6248cA398FA25D6712;
        swapRequest.amount = 10000000000000000;
        swapRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        swapRequest.toToken = USDC;
        swapRequest.data = bytes(
            hex"0502b1c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000b82bc10000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340397ff1542f962076d0bfe58ea045ffa2d347aca0cfee7c08"
        );

        TestLocalVars memory testLocalVars;

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        testLocalVars.swapImplData = abi.encodeWithSelector(
            OneInch.SWAP_WITHIN_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.data
        );

        uint32 across_bridgeRouteId = 514;
        AcrossImpl.AcrossBridgeData memory acrossBridgeData;
        acrossBridgeData.relayerFeePct = 0;
        acrossBridgeData.token = USDC;
        acrossBridgeData.quoteTimestamp = uint32(block.timestamp);
        acrossBridgeData.receiverAddress = recipient1;
        acrossBridgeData.toChainId = 42161;
        acrossBridgeData.metadata = metadata;
        bytes memory acrossDataBytes = abi.encode(acrossBridgeData);

        uint32 hop_bridgeRouteId = 515;
        HopImplL1.HopData memory hopData;
        hopData.token = USDC;
        hopData.receiverAddress = recipient2;
        hopData.l1bridgeAddr = 0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
        hopData.relayer = 0x0000000000000000000000000000000000000000;
        hopData.amountOutMin = 0;
        hopData.relayerFee = 0;
        hopData.toChainId = 42161;
        hopData.deadline = block.timestamp + 100000;
        hopData.metadata = metadata;
        bytes memory hopDataBytes = abi.encode(hopData);

        testLocalVars.bridgeRouteIds = new uint32[](2);
        testLocalVars.bridgeRouteIds[0] = across_bridgeRouteId;
        testLocalVars.bridgeRouteIds[1] = hop_bridgeRouteId;

        testLocalVars.bridgeDataItems = new bytes[](2);
        testLocalVars.bridgeDataItems[0] = acrossDataBytes;
        testLocalVars.bridgeDataItems[1] = hopDataBytes;

        testLocalVars.bridgeRatios = new uint256[](2);
        testLocalVars.bridgeRatios[0] = 30e18;
        testLocalVars.bridgeRatios[1] = 70e18;

        testLocalVars.eventDataItems = new bytes[](2);
        testLocalVars.eventDataItems[0] = abi.encodePacked(
            "Bridge ERC20 on Across"
        );
        testLocalVars.eventDataItems[1] = abi.encodePacked(
            "Bridge ERC20 on Hop"
        );

        // Emits Event
        uint256 expected_Swapped_Amount = 12191743;
        emit SocketSwapTokens(
            swapRequest.inputToken,
            swapRequest.toToken,
            expected_Swapped_Amount,
            swapRequest.amount,
            ONEINCH,
            address(socketGateway)
        );

        uint256 expected_BridgedAmount_On_Across = (expected_Swapped_Amount *
            testLocalVars.bridgeRatios[0]) / 100e18;

        emit SocketBridge(
            expected_BridgedAmount_On_Across,
            USDC,
            acrossBridgeData.toChainId,
            ACROSS,
            sender,
            recipient2
        );

        uint256 expected_BridgedAmount_On_Hop = expected_Swapped_Amount -
            expected_BridgedAmount_On_Across;

        assertEq(
            expected_BridgedAmount_On_Across + expected_BridgedAmount_On_Hop,
            expected_Swapped_Amount
        );

        emit SocketBridge(
            expected_BridgedAmount_On_Hop,
            USDC,
            hopData.toChainId,
            HOP,
            sender,
            recipient2
        );

        // fund sender with native balance which is to be swapped to ERC20 token
        deal(sender, swapRequest.amount);

        // Assert balances before swap-n-multiBridge
        assertEq(sender.balance, swapRequest.amount);
        assertEq(address(socketGateway).balance, 0);
        assertEq(IERC20(USDC).balanceOf(sender), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(recipient1), 0);
        assertEq(IERC20(USDC).balanceOf(recipient2), 0);

        uint256 gasStockbeforeSwap = gasleft();

        socketGateway.swapAndMultiBridge{value: swapRequest.amount}(
            ISocketRequest.SwapMultiBridgeRequest(
                513,
                testLocalVars.swapImplData,
                testLocalVars.bridgeRouteIds,
                testLocalVars.bridgeDataItems,
                testLocalVars.bridgeRatios,
                testLocalVars.eventDataItems
            )
        );

        uint256 gasStockAfterSwap = gasleft();

        // Assert for expected balances after swap-n-multiBridge
        assertEq(IERC20(USDC).balanceOf(sender), 0);
        assertEq(sender.balance, 0);
        assertEq(address(socketGateway).balance, 0);
        assertEq(IERC20(USDC).balanceOf(sender), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(recipient1), 0);
        assertEq(IERC20(USDC).balanceOf(recipient2), 0);

        console.log(
            "Swap-Native on OneInch And Bridge-ERC20 via Across, Hop - GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
