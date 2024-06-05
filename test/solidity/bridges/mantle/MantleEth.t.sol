// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {NativeOptimismStack} from "../../../../src/bridges/optimism/l1/NativeOpStack.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract NativeOptimismStackTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    address customBridgeAddress = 0x95fC37A27a2f68e3A647CDc081F0A89bb47c3012;
    address constant sender1 = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
    uint256 amount = 0xf4240;
    address constant receiver = 0x8BE6C8b2cA6f39fd70C9DdF35B4c34301AE10c0F;
    uint256 toChainId = 5000;

    NativeOptimismStack internal baseBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 19226413);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        baseBridgeImpl = new NativeOptimismStack(
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(baseBridgeImpl);

        // Emits Event
        emit NewRouteAdded(0, address(baseBridgeImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testNativeBridging() public {
        vm.startPrank(sender1);
        bytes memory _data = "0x";
        uint32 _l2Gas = 2000000;
        bytes32 bridgeHash = "optimism";
        deal(sender1, amount);
        assertEq(sender1.balance, amount);
        assertEq(address(socketGateway).balance, 0);

        bytes memory impldata = abi.encodeWithSelector(
            baseBridgeImpl
                .NATIVE_OPTIMISM_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            customBridgeAddress,
            _l2Gas,
            amount,
            toChainId,
            metadata,
            bridgeHash,
            "0x"
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount}(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "gnosis-Bridge-Router native ETH from Ethereum to weth on xdai via omni bridge helper contract costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
