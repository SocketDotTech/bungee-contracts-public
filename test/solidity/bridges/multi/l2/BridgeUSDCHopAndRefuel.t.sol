// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopImplL2} from "../../../../../src/bridges/hop/l2/HopImplL2.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";
import {RefuelBridgeImpl} from "../../../../../src/bridges/refuel/refuel.sol";

contract BridgeL2USDCHopAndRefueltest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //Polygon Mainnet
    address public constant REFUEL_BRIDGE =
        0xAC313d7491910516E06FBfC2A0b5BB49bb072D91;
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    HopImplL2 internal hopBridgeImpl;
    RefuelBridgeImpl internal refuelBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"));
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopImplL2(
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

    //refuel plus USDC bridge through Hop : Polygon -> Arbitrum
    function testMultiBridgeRequest() public {
        vm.startPrank(sender1);

        uint256 hopBridgeAmount = 250e6;

        address _hopAMM = 0x76b22b8C1079A44F1211D867D68b1eda76a635A7;
        // fees passed to relayer
        uint256 _bonderFee = 200000;
        uint256 _amountOutMin = 240e6;
        uint256 _deadline = block.timestamp + 100000;
        uint256 _amountOutMinDestination = 240e6;
        uint256 _deadlineDestination = block.timestamp + 100000;
        bytes32 metadata = 0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory hopBridgeImplData = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            sender1,
            USDC,
            _hopAMM,
            hopBridgeAmount,
            42161,
            HopImplL2.HopBridgeRequestData(
                _bonderFee,
                _amountOutMin,
                _deadline,
                _amountOutMinDestination,
                _deadlineDestination,
                metadata
            )
        );

        uint256 refuelBridgeAmount = 1e16;

        //sequence of arguments for implData: _amount, _receiverAddress, _toChainId
        bytes memory refuelImpldata = abi.encodeWithSelector(
            refuelBridgeImpl.REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            refuelBridgeAmount,
            sender1,
            42161,
            metadata
        );

        deal(sender1, refuelBridgeAmount);
        deal(address(USDC), address(sender1), hopBridgeAmount);
        assertEq(IERC20(USDC).balanceOf(sender1), hopBridgeAmount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        IERC20(USDC).approve(address(socketGateway), hopBridgeAmount);

        uint32[] memory routes = new uint32[](2);
        routes[0] = 513;
        routes[1] = 514;

        bytes[] memory implDataItems = new bytes[](2);
        implDataItems[0] = hopBridgeImplData;
        implDataItems[1] = refuelImpldata;

        bytes[] memory eventDataItems = new bytes[](2);
        eventDataItems[0] = abi.encodePacked("HopBridge");
        eventDataItems[1] = abi.encodePacked("RefuelBridge");

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoutes{value: refuelBridgeAmount}(
            routes,
            implDataItems,
            eventDataItems
        );

        uint256 gasStockAfterBridge = gasleft();

        //post refuelAndHop, balances of sender1 and socketGateway should be 0.
        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);
        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        console.log(
            "HopBridge_USDC and Refuel on Polygon gas-cost: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
