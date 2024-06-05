// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {NativePolygonImpl} from "../../../../src/bridges/polygon/NativePolygon.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract PolygonBridgeNativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant rootChainManagerProxy =
        0xA0c68C638235ee32657e8f720a23ceC1bFc77C77;
    address constant erc20PredicateProxy =
        0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;
    NativePolygonImpl internal nativePolygonImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16333752);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        nativePolygonImpl = new NativePolygonImpl(
            rootChainManagerProxy,
            erc20PredicateProxy,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(nativePolygonImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeNative() public {
        uint256 amount = 20e18;
        uint256 value = 20e18;
        bytes memory eventData = abi.encodePacked("native-polygon", "NATIVE");

        //sequence of arguments for implData: amount, recipient
        bytes memory impldata = abi.encodeWithSelector(
            nativePolygonImpl
                .NATIVE_POLYGON_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            metadata,
            recipient
        );

        deal(sender1, amount);
        assertEq(sender1.balance, amount);
        assertEq(recipient.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        vm.startPrank(sender1);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: value}(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(recipient.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "gas-cost for NativePolygon Native-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
