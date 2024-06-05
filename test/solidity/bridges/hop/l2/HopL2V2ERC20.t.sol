// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopImplL2V2 as HopImplL2} from "../../../../../src/bridges/hop/l2/HopImplL2V2.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract HopL2PolygonToArbitrumUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant sender1 = 0x0E1B5AB67aF1c99F8c7Ebc71f41f75D4D6211e53;
    HopImplL2 internal hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 37663689);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopImplL2(
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

    function testBridgeUSDC() public {
        address _hopAMM = 0x76b22b8C1079A44F1211D867D68b1eda76a635A7;
        // fees passed to relayer
        uint256 _bonderFee = 200000;
        uint256 _amountOutMin = 40e6;
        uint256 _deadline = block.timestamp + 60 * 20;
        uint256 _amountOutMinDestination = 40e6;
        uint256 _deadlineDestination = block.timestamp + 60 * 20;

        address[] memory routers = new address[](1);
        address[] memory tokens = new address[](1);

        routers[0] = _hopAMM;
        tokens[0] = USDC;

        vm.startPrank(owner);
        socketGateway.setApprovalForRouters(routers, tokens, true);
        vm.stopPrank();
        vm.startPrank(sender1);
        uint256 amount = 50e6;
        bytes memory eventData = abi.encodePacked(
            "hop-L2",
            "PolygonToArbitrumUSDC"
        );

        bytes memory packedBytes = bytes.concat(
            bytes4(uint32(385)),
            optimisedBridgeErc20Selector,
            bytes20(USDC),
            bytes20(_hopAMM),
            bytes20(sender1),
            bytes16(uint128(amount)),
            bytes16(uint128(_bonderFee)),
            bytes16(uint128(_amountOutMin)),
            bytes16(uint128(_amountOutMinDestination)),
            bytes4(uint32(42161))
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        // bytes memory impldata = abi.encodeWithSelector(
        //     hopBridgeImpl.HOP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
        //     sender1,
        //     USDC,
        //     _hopAMM,
        //     amount,
        //     42161,
        //     HopImplL2.HopBridgeRequestData(
        //         _bonderFee,
        //         _amountOutMin,
        //         _deadline,
        //         _amountOutMinDestination,
        //         _deadlineDestination,
        //         metadata
        //     )
        // );

        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        IERC20(USDC).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        address(socketGateway).call(packedBytes);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        console.log(
            "Hop-L2-Router : gas cost for USDC-bridge from Polygon -> Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );
    }
}
