// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopCctpImplL2} from "../../../../../src/bridges/hop/l2/HopCctpImpl.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract HopL2PolygonToArbitrumUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant sender1 = 0x0E1B5AB67aF1c99F8c7Ebc71f41f75D4D6211e53;
    address constant _hopAMM = 0x1CD391bd1D915D189dE162F0F1963C07E60E4CD6;

    HopCctpImplL2 internal hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 55090282);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopCctpImplL2(
            address(_hopAMM),
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(hopBridgeImpl);

        // Emits Event
        emit NewRouteAdded(0, address(hopBridgeImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct HopBridgeData {
        // The chainId of the destination chain
        uint256 toChainId;
        // The address receiving funds at the destination
        address recipient;
        // amount is the amount the user wants to send plus the Bonder fee
        uint256 amount;
        // fees passed to relayer
        uint256 bonderFee;
        // route identifier for
        bytes path;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        /// @notice address of token being bridged
        address token;
        bool isSwapTx;
        bytes32 metadata;
    }

    function testBridgeUSDC() public {
        vm.startPrank(sender1);

        uint256 amount = 50e6;
        uint256 _bonderFee = 200000;

        bytes
            memory paths = hex"2791bca1f2de4661ed88a30c99a7a9449aa841740000643c499c542cef5e3811e1192ce70d8cc03d5c3359";

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            hopBridgeImpl.HOP_CCTP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            HopBridgeData(
                10,
                0x1CD391bd1D915D189dE162F0F1963C07E60E4CD6,
                1000000,
                _bonderFee,
                paths,
                994888,
                USDC,
                true,
                metadata
            )
        );

        deal(address(USDC), address(sender1), amount);

        IERC20(USDC).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        // assertEq(IERC20(USDC).balanceOf(sender1), 0);
        // assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        console.log(
            "Hop-L2-Router : gas cost for USDC-bridge from Polygon -> Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );
    }
}
