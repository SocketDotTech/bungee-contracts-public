// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopImplL1} from "../../../../../src/bridges/hop/l1/HopImplL1.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";
import {RefuelBridgeImpl} from "../../../../../src/bridges/refuel/refuel.sol";

contract BridgeUSDCHopAndRefueltest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //ETH Mainnet
    address public constant REFUEL_BRIDGE =
        0xb584D4bE1A5470CA1a8778E9B86c81e165204599;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    HopImplL1 internal hopBridgeImpl;
    RefuelBridgeImpl internal refuelBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"));
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopImplL1(
            address(socketGateway),
            address(socketGateway)
        );
        refuelBridgeImpl = new RefuelBridgeImpl(
            REFUEL_BRIDGE,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(hopBridgeImpl);
        address route_1 = address(refuelBridgeImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);

        socketGateway.addRoute(route_0);

        emit NewRouteAdded(1, route_1);
        socketGateway.addRoute(route_1);

        vm.stopPrank();
    }

    //refuel plus USDC bridge through Hop : ETH -> Arbitrum
    function testMultiBridgeRequest() public {
        address _l1bridgeAddr = 0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 290e6;
        uint256 _relayerFee = 0;
        uint256 _deadline = block.timestamp + 100000;
        uint256 hopBridgeAmount = 300e6;
        address token = USDC;

        bytes memory hopBridgeImplData = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            sender1,
            token,
            _l1bridgeAddr,
            _relayer,
            42161,
            hopBridgeAmount,
            _amountOutMin,
            _relayerFee,
            HopImplL1.HopERC20Data(_deadline, metadata)
        );

        deal(address(USDC), address(sender1), hopBridgeAmount);
        assertEq(IERC20(USDC).balanceOf(sender1), hopBridgeAmount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        vm.startPrank(sender1);

        IERC20(USDC).approve(address(socketGateway), hopBridgeAmount);

        uint256 refuelAmount = 1e16;

        deal(sender1, refuelAmount);
        assertEq(sender1.balance, refuelAmount);
        assertEq(address(socketGateway).balance, 0);

        //sequence of arguments for implData: _amount, _receiverAddress, _toChainId
        bytes memory refuelImpldata = abi.encodeWithSelector(
            refuelBridgeImpl.REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            refuelAmount,
            sender1,
            56,
            metadata
        );

        uint32[] memory routes = new uint32[](2);
        routes[0] = 513;
        routes[1] = 514;

        bytes[] memory implDataItems = new bytes[](2);
        implDataItems[0] = hopBridgeImplData;
        implDataItems[1] = refuelImpldata;

        bytes[] memory eventDataItems = new bytes[](2);
        eventDataItems[0] = abi.encodePacked("HopBridgeERC20");
        eventDataItems[1] = abi.encodePacked("RefuelBridge");

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoutes{value: refuelAmount}(
            routes,
            implDataItems,
            eventDataItems
        );

        uint256 gasStockAfterBridge = gasleft();

        //afte refuel, eth-balance of sender must be 0
        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        //after hop, USDC balance of socketGateway and sender should be 0
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(sender1), 0);

        console.log(
            "HopBridge_USDC and Refuel on ETH-L1 gas-cost: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
