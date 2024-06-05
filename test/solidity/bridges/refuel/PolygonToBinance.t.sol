// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {RefuelBridgeImpl} from "../../../../src/bridges/refuel/refuel.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketGateway} from "../../../../src/interfaces/ISocketGateway.sol";

contract RefuelPolygonToBinanceRefuelTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address public constant REFUEL_BRIDGE =
        0xAC313d7491910516E06FBfC2A0b5BB49bb072D91;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    RefuelBridgeImpl internal refuelBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"));
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        refuelBridgeImpl = new RefuelBridgeImpl(
            REFUEL_BRIDGE,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(refuelBridgeImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);

        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testSendBridgeRequest() public {
        uint256 bridgeAmount = 1e16;
        bytes memory eventData = abi.encodePacked("refuel-polygon", "NATIVE");

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory impldata = abi.encodeWithSelector(
            refuelBridgeImpl.REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            1e16,
            receiver,
            56,
            metadata
        );

        deal(sender1, bridgeAmount);
        assertEq(sender1.balance, bridgeAmount);
        assertEq(address(socketGateway).balance, 0);
        assertEq(receiver.balance, 0);

        vm.startPrank(sender1);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: bridgeAmount}(
            513,
            impldata,
            eventData
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);
        assertEq(receiver.balance, 0);

        console.log(
            "Refuel Native Bridge from Polygon -> Binance costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
