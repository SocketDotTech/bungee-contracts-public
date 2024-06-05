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

contract HyphenEthToArbitrumBridgeUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
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

    function testBridgeUSDC() public {
        uint256 amount = 100e6;
        bytes memory eventData = abi.encodePacked(
            "hyphen",
            "EthToArbitrumUSDC"
        );

        vm.startPrank(sender1);

        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        IERC20(USDC).approve(address(socketGateway), amount);

        bytes memory impldata = abi.encodeWithSelector(
            hyphenImpl.HYPHEN_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            metadata,
            sender1,
            USDC,
            42161
        );

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        console.log(
            "Hyphen-Bridge USDC from Ethereum to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
