// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {NativeArbitrumImpl} from "../../../../src/bridges/arbitrum/l1/NativeArbitrum.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract ArbitrumBridgeUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant nativeArbitrumRouterAddress =
        0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;
    NativeArbitrumImpl internal nativeArbitrumImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16333752);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        nativeArbitrumImpl = new NativeArbitrumImpl(
            nativeArbitrumRouterAddress,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(nativeArbitrumImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeUSDC() public {
        address gatewayAddress = 0xcEe284F754E854890e311e3280b767F80797180d;
        uint256 maxGas = 357500;
        uint256 gasPriceBid = 300000000;
        bytes
            memory data = hex"000000000000000000000000000000000000000000000000000097d65f01cc4000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000";

        uint256 bridgeAmount = 1000e6;
        uint256 bridgeValue = 274196972748864;
        bytes memory eventData = abi.encodePacked("native-arbitrum", "USDC");

        //sequence of arguments for implData: receiverAddress, token, gatewayAddress, amount, value, maxGas, gasPriceBid, data
        bytes memory impldata = abi.encodeWithSelector(
            nativeArbitrumImpl
                .NATIVE_ARBITRUM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            bridgeAmount,
            bridgeValue,
            maxGas,
            gasPriceBid,
            metadata,
            recipient,
            USDC,
            gatewayAddress,
            data
        );

        deal(sender1, bridgeValue);
        assertEq(sender1.balance, bridgeValue);
        deal(address(USDC), address(sender1), bridgeAmount);
        assertEq(IERC20(USDC).balanceOf(sender1), bridgeAmount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(recipient), 0);

        vm.startPrank(sender1);

        IERC20(USDC).approve(address(socketGateway), bridgeAmount);

        uint256 gasStockBefore = gasleft();

        socketGateway.executeRoute{value: bridgeValue}(
            513,
            impldata,
            eventData
        );

        uint256 gasStockAfter = gasleft();

        //After bridging, balance of sender, recipient and socketGateway should be equal to 0.
        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(recipient), 0);
        assertEq(sender1.balance, 0);
        assertEq(recipient.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "NativeArbitrum on Eth-Mainnet gas-cost for USDC-bridge: ",
            gasStockBefore - gasStockAfter
        );

        vm.stopPrank();
    }
}
