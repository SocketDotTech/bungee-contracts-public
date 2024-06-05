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

contract ArbitrumBridgeDAITest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
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

    function testBridgeDAI() public {
        address gatewayAddress = 0xD3B5b60020504bc3489D6949d545893982BA3011;
        uint256 maxGas = 357500;
        uint256 gasPriceBid = 300000000;
        bytes
            memory data = hex"000000000000000000000000000000000000000000000000000097d65f01cc4000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000";

        uint256 bridgeAmount = 1000e18;
        uint256 bridgeValue = 274196972748864;
        bytes memory eventData = abi.encodePacked("native-arbitrum", "DAI");

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
            DAI,
            gatewayAddress,
            data
        );

        deal(sender1, bridgeValue);
        assertEq(sender1.balance, bridgeValue);
        deal(address(DAI), address(sender1), bridgeAmount);
        assertEq(IERC20(DAI).balanceOf(sender1), bridgeAmount);
        assertEq(IERC20(DAI).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(DAI).balanceOf(recipient), 0);

        vm.startPrank(sender1);

        IERC20(DAI).approve(address(socketGateway), bridgeAmount);

        uint256 gasStockBefore = gasleft();

        socketGateway.executeRoute{value: bridgeValue}(
            513,
            impldata,
            eventData
        );

        uint256 gasStockAfter = gasleft();

        //After bridging, balance of sender, recipient and socketGateway should be equal to 0.
        assertEq(IERC20(DAI).balanceOf(sender1), 0);
        assertEq(IERC20(DAI).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(DAI).balanceOf(recipient), 0);
        assertEq(sender1.balance, 0);
        assertEq(recipient.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "NativeArbitrum on Eth-Mainnet gas-cost for DAI-bridge: ",
            gasStockBefore - gasStockAfter
        );

        vm.stopPrank();
    }
}
