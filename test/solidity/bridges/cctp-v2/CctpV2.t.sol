// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {CctpV2Impl} from "../../../../src/bridges/cctp-v2/CctpV2.sol";
import {ZeroXSwapImpl} from "../../../../src/swap/zerox/ZeroXSwapImpl.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import "../../../../lib/forge-std/src/console.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
contract CctpV2Test is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    struct SwapRequest {
        uint32 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    /* Ethereum Mainnet */
    address constant tokenMessenger =
        0x28b5a0e9C621a5BadaA536219b3a228C8168cf5d;
    address constant feeCollector = 0xc91E5068968ACAEC9C8E7C056390d9e3CB34f7FC;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC on Ethereum
    address constant zeroXExchangeProxy =
        0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    address constant sender = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    ZeroXSwapImpl internal zeroXSwapImpl;
    CctpV2Impl internal cctpV2Impl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 22025619);
        vm.selectFork(fork);

        socketGateway = createSocketGateway();
        zeroXSwapImpl = new ZeroXSwapImpl(
            zeroXExchangeProxy,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);
        address route_0 = address(zeroXSwapImpl);
        vm.expectEmit(true, true, true, true);
        emit NewRouteAdded(385, address(zeroXSwapImpl));
        socketGateway.addRoute(route_0);

        cctpV2Impl = new CctpV2Impl(
            tokenMessenger,
            feeCollector,
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(cctpV2Impl);

        // Emits Event
        vm.expectEmit(true, true, true, true);
        emit NewRouteAdded(386, address(cctpV2Impl));
        socketGateway.addRoute(route_1);
        vm.stopPrank();
    }

    function test_functionSelectors() public {
        assertEq(
            cctpV2Impl.CCTP_V2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            bytes4(0x3ca7f5bc)
        );
        assertEq(cctpV2Impl.CCTP_V2_SWAP_BRIDGE_SELECTOR(), bytes4(0x4db9cf6a));
    }

    function test_bridgeAfterSwap() public {
        uint256 amount = 1000000; // 1 USDC
        uint256 feeAmount = 100; // 0.1 USDC fee
        uint32 destinationDomain = 1; // Example destination domain - avalanche
        uint256 maxFee = 1000; // Max fee for fast transfer
        uint32 minFinalityThreshold = 20; // Example finality threshold

        // Setup test data
        address receiver = address(0x123);
        uint256 toChainId = 137; // Polygon

        // Prepare token and approvals
        // simulate socketGateway having funds after a swap
        deal(USDC, address(socketGateway), amount);
        vm.startPrank(sender);
        ERC20(USDC).approve(address(socketGateway), amount);

        // Encode bridge data
        CctpV2Impl.CctpData memory cctpData = CctpV2Impl.CctpData({
            token: USDC,
            receiverAddress: receiver,
            destinationDomain: destinationDomain,
            toChainId: toChainId,
            feeAmount: feeAmount,
            maxFee: maxFee,
            minFinalityThreshold: minFinalityThreshold,
            metadata: metadata
        });

        bytes memory bridgeData = abi.encode(cctpData);

        // Encode function call
        bytes memory impldata = abi.encodeWithSelector(
            cctpV2Impl.bridgeAfterSwap.selector,
            amount,
            bridgeData
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(386, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "CCTP V2 bridge after swap gas cost: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }

    function test_bridgeERC20To() public {
        // Setup test data
        uint256 amount = 1000000; // 1 USDC
        uint256 feeAmount = 100; // 0.1 USDC fee
        uint32 destinationDomain = 1; // Example destination domain - avalanche
        uint256 maxFee = 1000; // Max fee for fast transfer
        uint32 minFinalityThreshold = 20; // Example finality threshold
        address receiver = address(0x123);
        uint256 toChainId = 137; // Polygon

        // Prepare token and approvals
        deal(USDC, sender, 100 ether);
        vm.startPrank(sender);
        ERC20(USDC).approve(address(socketGateway), amount);

        // Encode function call
        bytes memory impldata = abi.encodeWithSelector(
            cctpV2Impl.CCTP_V2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            metadata,
            receiver,
            USDC,
            toChainId,
            destinationDomain,
            feeAmount,
            maxFee,
            minFinalityThreshold
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(386, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "CCTP V2 ERC20 bridge gas cost: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }

    function test_swapAndBridge() public {
        address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT on Ethereum
        // Setup test data
        uint256 amount = 1000000; // 1 USDC
        uint256 feeAmount = 100; // 0.1 USDC fee
        uint32 destinationDomain = 1; // Example destination domain - avalanche
        uint256 maxFee = 1000; // Max fee for fast transfer
        uint32 minFinalityThreshold = 20; // Example finality threshold
        address receiver = address(0x123);
        uint256 toChainId = 137; // Polygon

        SwapRequest memory swapRequest;
        console.log("socketGateway", address(socketGateway));
        swapRequest.id = 385;
        swapRequest
            .receiverAddress = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
        swapRequest.amount = amount;
        swapRequest.inputToken = USDT;
        swapRequest.toToken = USDC;

        // https://api.0x.org/swap/v1/quote?buyToken=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&sellToken=0xdAC17F958D2ee523a2206206994597C13D831ec7&sellAmount=1000000&slippagePercentage=1&skipValidation=true
        bytes memory zeroxExtraData = bytes(
            hex"d9627aa4000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000f4240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48869584cd000000000000000000000000447d72fcecb054ad0ca5ad4defed3a744ab86ef600000000000000000000000000000000000000001cee3f4713255fe45c09a278"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory swapImplData = abi.encodeWithSelector(
            ZeroXSwapImpl.performActionWithIn.selector,
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            metadata,
            zeroxExtraData
        );

        deal(USDT, address(sender), 100 ether);
        vm.startPrank(sender);
        SafeTransferLib.safeApprove(
            ERC20(USDT),
            address(socketGateway),
            100 ether
        );

        // Encode bridge data
        CctpV2Impl.CctpDataNoToken memory cctpData = CctpV2Impl
            .CctpDataNoToken({
                receiverAddress: receiver,
                destinationDomain: destinationDomain,
                toChainId: toChainId,
                feeAmount: feeAmount,
                maxFee: maxFee,
                minFinalityThreshold: minFinalityThreshold,
                metadata: metadata
            });

        // Encode function call
        bytes memory impldata = abi.encodeWithSelector(
            cctpV2Impl.CCTP_V2_SWAP_BRIDGE_SELECTOR(),
            swapRequest.id,
            swapImplData,
            cctpData
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(386, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "CCTP V2 swap and bridge gas cost: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
