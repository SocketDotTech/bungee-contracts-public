// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {MayanBridgeImpl} from "../../../../src/bridges/mayan/MayanBridge.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IMayanForwarderContract} from "../../../../src/bridges/mayan/interfaces/IMayan.sol";
import "../../../../lib/forge-std/src/console.sol";

contract MayanErc20 is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    uint256 value = 139755662577002220;
    address constant senderAddress = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
    uint256 amount = 1000000000000;

    address constant USDC = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;

    struct BridgeDataWithNoToken {
        address receiver;
        bytes32 metadata;
        uint256 toChainId;
        bytes protocolData; // Mayan protocol data
        address mayanProtocolAddress; // Final mayan contract where protocol data is excecuted
        bool isNonEvmDest;
        bytes32 nonEvmAddress;
    }

    MayanBridgeImpl internal mayanImpl;

    address constant mayanForwarder =
        0x0654874eb7F59C6f5b39931FC45dC45337c967c3;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 59976231);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        mayanImpl = new MayanBridgeImpl(
            mayanForwarder,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(mayanImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeErc20() public {
        bytes memory impldata = abi.encodeWithSelector(
            mayanImpl.MAYAN_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            USDC,
            amount,
            BridgeDataWithNoToken(
                0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F,
                metadata,
                137,
                hex"94454a5d0000000000000000000000003c499c542cef5e3811e1192ce70d8cc03d5c3359000000000000000000000000000000000000000000000000000000e8d4a510000000000000000000000000000000000000000000000000000000000006085eee00000000000000000000000000000000000000000000000000000000000000005bde4b9f19ebab9e3b5582d83a8e4dbf8a5c772475df3729a76cd9c15cfeb34f0000000000000000000000000000000000000000000000000000000000000005ccc17da2378a3dd885a3a46d21eaee35540503c3c316f80e57ea27a73a2895b0e7a885e54d080de088b949c28db5e166ccd25658e4752f5faed32c2ebc55dc45",
                0xF18f923480dC144326e6C65d4F3D47Aa459bb41C,
                true,
                hex"0000000000000000000000008BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F"
            )
        );

        vm.startPrank(senderAddress);
        deal(address(USDC), address(senderAddress), amount);
        IERC20(USDC).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "Polygon->Optimism gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
