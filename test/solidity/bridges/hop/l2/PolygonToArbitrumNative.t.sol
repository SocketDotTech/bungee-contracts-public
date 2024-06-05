// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopImplL2} from "../../../../../src/bridges/hop/l2/HopImplL2.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract HopPolygonToETHNativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    //Polygon Mainnet
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
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

    function testBridgeNative() public {
        vm.startPrank(sender1);

        address _hopAMM = 0x884d1Aa15F9957E1aEAA86a82a72e49Bc2bfCbe3;
        // fees passed to relayer
        uint256 _bonderFee = 20e16;
        uint256 _amountOutMin = 15e18;
        uint256 _deadline = block.timestamp + 100000;
        uint256 _amountOutMinDestination = 15e18;
        uint256 _deadlineDestination = block.timestamp + 100000;
        bytes memory eventData = abi.encodePacked(
            "hop-L2",
            "PolygonToArbitrumNative"
        );

        uint256 amount = 20e18;
        deal(sender1, amount);

        assertEq(sender1.balance, amount);
        assertEq(address(socketGateway).balance, 0);

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            sender1,
            _hopAMM,
            amount,
            42161,
            _bonderFee,
            _amountOutMin,
            _deadline,
            _amountOutMinDestination,
            _deadlineDestination,
            metadata
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount}(513, impldata);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "HopL2-Bridge-Router NativeToken from Polygon to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
