// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopImplL1} from "../../../../../src/bridges/hop/l1/HopImplL1.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";
import {RefuelBridgeImpl} from "../../../../../src/bridges/refuel/refuel.sol";

contract BridgeNativeHopAndRefueltest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //ETH Mainnet
    address public constant REFUEL_BRIDGE =
        0xb584D4bE1A5470CA1a8778E9B86c81e165204599;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    HopImplL1 internal hopBridgeImpl;
    RefuelBridgeImpl internal refuelBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"));
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopImplL1(
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
        emit NewRouteAdded(0, address(hopBridgeImpl));

        socketGateway.addRoute(route_0);

        emit NewRouteAdded(1, address(refuelBridgeImpl));
        socketGateway.addRoute(route_1);

        vm.stopPrank();
    }

    //refuel plus Native bridge through Hop : ETH -> Arbitrum
    function testMultiBridgeRequest() public {
        vm.startPrank(sender1);

        address _l1bridgeAddr = 0xb8901acB165ed027E32754E0FFe830802919727f;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 0;
        uint256 _relayerFee = 0;
        uint256 _deadline = 0;

        uint256 hopAmount = 2e16;

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory hopBridgeImplData = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            sender1,
            _l1bridgeAddr,
            _relayer,
            137,
            hopAmount,
            _amountOutMin,
            _relayerFee,
            _deadline,
            metadata
        );

        uint256 refuelAmount = 1e16;
        //sequence of arguments for implData: _amount, _receiverAddress, _toChainId
        bytes memory refuelImpldata = abi.encodeWithSelector(
            refuelBridgeImpl.REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            refuelAmount,
            sender1,
            56,
            metadata
        );

        deal(sender1, hopAmount + refuelAmount);
        assertEq(sender1.balance, hopAmount + refuelAmount);
        assertEq(address(socketGateway).balance, 0);

        uint32[] memory routes = new uint32[](2);
        routes[0] = 513;
        routes[1] = 514;

        bytes[] memory implDataItems = new bytes[](2);
        implDataItems[0] = hopBridgeImplData;
        implDataItems[1] = refuelImpldata;

        bytes[] memory eventDataItems = new bytes[](2);
        eventDataItems[0] = abi.encodePacked("HopBridgeNative");
        eventDataItems[1] = abi.encodePacked("RefuelBridge");

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoutes{value: 3e16}(
            routes,
            implDataItems,
            eventDataItems
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "Hop Native Bridge and Refuel on ETH-L1 gas-cost: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
