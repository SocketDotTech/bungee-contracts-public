// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {OneInchImpl} from "../../../../src/swap/oneinch/OneInchImpl.sol";
import {CelerImpl} from "../../../../src/bridges/cbridge/CelerImpl.sol";
import {CelerStorageWrapper} from "../../../../src/bridges/cbridge/CelerStorageWrapper.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";

contract OneInchSwapNativeCelerERC20Test is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    address public immutable ONEINCH_AGGREGATOR =
        0x1111111254EEB25477B68fb85Ed929f73A960582;
    address constant CELER_BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    address constant WETH_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //ETH Mainnet
    // whale address
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    OneInchImpl internal OneInch;
    CelerImpl internal celerImpl;
    CelerStorageWrapper internal celerStorageWrapper;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16257266);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        OneInch = new OneInchImpl(
            0x1111111254EEB25477B68fb85Ed929f73A960582,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(OneInch);
        // Emits Event
        emit NewRouteAdded(0, route_0);
        socketGateway.addRoute(route_0);

        celerStorageWrapper = new CelerStorageWrapper(address(socketGateway));
        celerImpl = new CelerImpl(
            CELER_BRIDGE,
            WETH_ADDRESS,
            address(celerStorageWrapper),
            address(socketGateway),
            address(socketGateway)
        );
        address route_1 = address(celerImpl);
        socketGateway.addRoute(route_1);

        vm.stopPrank();
    }

    function testSocketGatewaySwapAndBridge() public {
        vm.startPrank(sender1);

        SwapRequest memory swapRequest;

        swapRequest.id = 513;
        swapRequest
            .receiverAddress = 0x8657AB84A5B7Fc75B9327d6248cA398FA25D6712;
        swapRequest.amount = 10e18;
        swapRequest.inputToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        swapRequest.toToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        swapRequest.data = bytes(
            hex"e449022e0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000002bdd23fdd00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f5640cfee7c08"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory swapImplData = abi.encodeWithSelector(
            OneInch.SWAP_WITHIN_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.data
        );

        uint32 bridgeRouteId = 514;
        CelerImpl.CelerBridgeDataNoToken memory celerBridgeData;
        // celerBridgeData.token = USDC;
        celerBridgeData.receiverAddress = sender1;
        celerBridgeData.toChainId = 42161;
        celerBridgeData.nonce = uint64(block.timestamp);
        celerBridgeData.maxSlippage = 30000;
        celerBridgeData.metadata = metadata;
        bytes memory celerDataBytes = abi.encodeWithSelector(
            celerImpl.CELER_SWAP_BRIDGE_SELECTOR(),
            513,
            swapImplData,
            celerBridgeData
        );

        deal(sender1, swapRequest.amount);

        uint256 gasStockBeforeSwapAndBridge = gasleft();

        socketGateway.executeRoute{value: swapRequest.amount}(
            bridgeRouteId,
            celerDataBytes,
            abi.encode("SwapNative-BridgeERC20")
        );

        uint256 gasStockAfterSwapAndBridge = gasleft();

        console.log(
            "SwapAndBridge On OneInch and Celer -> GasUsed:  ",
            gasStockBeforeSwapAndBridge - gasStockAfterSwapAndBridge
        );

        vm.stopPrank();
    }
}
