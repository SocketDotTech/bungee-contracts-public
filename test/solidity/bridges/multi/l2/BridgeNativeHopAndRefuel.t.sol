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
import {RefuelBridgeImpl} from "../../../../../src/bridges/refuel/refuel.sol";

contract BridgeL2NativeHopAndRefueltest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //Polygon Mainnet
    address public constant REFUEL_BRIDGE =
        0xAC313d7491910516E06FBfC2A0b5BB49bb072D91;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    HopImplL2 internal hopBridgeImpl;
    RefuelBridgeImpl internal refuelBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"));
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopImplL2(
            address(socketGateway),
            address(socketGateway)
        );
        refuelBridgeImpl = new RefuelBridgeImpl(
            REFUEL_BRIDGE,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(hopBridgeImpl);
        address route_1 = address(refuelBridgeImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);

        socketGateway.addRoute(route_0);

        emit NewRouteAdded(1, route_1);
        socketGateway.addRoute(route_1);

        vm.stopPrank();
    }

    //refuel plus USDC bridge through Hop : Polygon -> Arbitrum
    function testMultiBridgeRequest() public {
        address _hopAMM = 0x884d1Aa15F9957E1aEAA86a82a72e49Bc2bfCbe3;
        // fees passed to relayer
        uint256 _bonderFee = 20e16;
        uint256 _amountOutMin = 15e18;
        uint256 _deadline = block.timestamp + 100000;
        uint256 _amountOutMinDestination = 15e18;
        uint256 _deadlineDestination = block.timestamp + 100000;

        uint256 hopBridgeAmount = 20e18;

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory hopBridgeImplData = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            sender1,
            _hopAMM,
            hopBridgeAmount,
            42161,
            _bonderFee,
            _amountOutMin,
            _deadline,
            _amountOutMinDestination,
            _deadlineDestination,
            metadata
        );

        uint256 refuelAmount = 1e18;
        uint256 toChainId = 42161;

        //sequence of arguments for implData: _amount, _receiverAddress, _toChainId
        bytes memory refuelImpldata = abi.encodeWithSelector(
            refuelBridgeImpl.REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            refuelAmount,
            sender1,
            toChainId,
            metadata
        );

        //fund sender1 with essential native for refuel and Hop
        deal(sender1, hopBridgeAmount + refuelAmount);
        assertEq(sender1.balance, hopBridgeAmount + refuelAmount);
        assertEq(address(socketGateway).balance, 0);

        uint32[] memory routes = new uint32[](2);
        routes[0] = 513;
        routes[1] = 514;

        bytes[] memory implDataItems = new bytes[](2);
        implDataItems[0] = hopBridgeImplData;
        implDataItems[1] = refuelImpldata;

        bytes[] memory eventDataItems = new bytes[](2);
        eventDataItems[0] = abi.encodePacked("HopBridge");
        eventDataItems[1] = abi.encodePacked("RefuelBridge");

        vm.startPrank(sender1);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoutes{value: refuelAmount + hopBridgeAmount}(
            routes,
            implDataItems,
            eventDataItems
        );

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "HopBridge Native and Refuel on Polygon gas-cost: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        //post refuel and hop-Bridge, assert that balance of sender and socketGateway is 0.
        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        vm.stopPrank();
    }
}
