// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {MayanBridgeImpl} from "../../../../src/bridges/mayan/MayanBridge.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IMayanForwarderContract} from "../../../../src/bridges/mayan/interfaces/IMayan.sol";
import "../../../../lib/forge-std/src/console.sol";

contract MayanEthToSolana is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    address constant senderAddress = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
    uint256 amount = 100000000000000000000;

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

    function testBridgeEtg() public {
        bytes memory impldata = abi.encodeWithSelector(
            mayanImpl.MAYAN_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            BridgeDataWithNoToken(
                0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F,
                metadata,
                137,
                hex"1eb1cff0000000000000000000000000000000000000000000000000000000002d0c9492000000000000000000000000000000000000000000000000000000000000073000000000000000000000000000000000000000000000000000000000005e65a7e7206ab7aa186c97b85ec6c1f31581bb9206a1ccbec9a9d6a916b211e3a7f19e00000000000000000000000000000000000000000000000000000000000000016dfa43f824c3b8b61e715fe8bf447f2aba63e59ab537f186cf665152c2114c390000000000000000000000008be6c8b2ca6f39fd70c9ddf35b4c34301ae10c0f000000000000000000000000000000000000000000000000000000000000001700000000000000000000000000000000000000000000000000000000000000000000000000000000000000008be6c8b2ca6f39fd70c9ddf35b4c34301ae10c0f00000000000000000000000082af49447d8a07e3bd95bd0d56f35241523fbab1000000000000000000000000000000000000000000000000000000000000001700000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000006764e57e000000000000000000000000000000000000000000000000000000006764e57e00000000000000000000000000000000000000000000000000000000001347d90000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000",
                0xBF5f3f65102aE745A48BD521d10BaB5BF02A9eF4,
                false,
                ""
            )
        );

        deal(senderAddress, amount);
        vm.startPrank(senderAddress);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount}(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "Polygon->Optimism gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
