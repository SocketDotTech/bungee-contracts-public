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

contract PolygonBridgeUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
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

    function testBridgeUSDC() public {
        uint256 amount = 100e6;
        uint256 value = 0;
        bytes memory eventData = abi.encodePacked("native-polygon", "USDC");

        //sequence of arguments for implData: _amount, _receiverAddress, _token
        bytes memory impldata = abi.encodeWithSelector(
            nativePolygonImpl
                .NATIVE_POLYGON_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            metadata,
            recipient,
            USDC
        );

        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(recipient), 0);

        vm.startPrank(sender1);

        IERC20(USDC).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: value}(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(recipient), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        console.log(
            "gas-cost for NativePolygon USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
