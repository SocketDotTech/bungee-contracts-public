// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {HyphenImpl} from "../../../../src/bridges/hyphen/Hyphen.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract HyphenEthToArbitrumNativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant liquidityPoolManager =
        0x2A5c2568b10A0E826BfA892Cf21BA7218310180b;

    HyphenImpl internal hyphenImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15819486);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hyphenImpl = new HyphenImpl(
            liquidityPoolManager,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(hyphenImpl);

        // Emits Event
        emit NewRouteAdded(0, address(hyphenImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testSendNativeBridging() public {
        vm.startPrank(sender1);

        uint256 amount = 1e18;
        bytes memory eventData = abi.encodePacked(
            "hyphen",
            "EthToArbitrumNative"
        );

        deal(sender1, amount);
        assertEq(sender1.balance, amount);
        assertEq(address(socketGateway).balance, 0);

        bytes memory impldata = abi.encodeWithSelector(
            hyphenImpl.HYPHEN_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            metadata,
            sender1,
            42161
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount}(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "Hyphen-Bridge-Router NativeToken from Ethereum to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
