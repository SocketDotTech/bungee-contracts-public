// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopImplL1V2 as HopImplL1} from "../../../../../src/bridges/hop/l1/HopImplL1V2.sol";
import "../../../../../src/bridges/hop/interfaces/IHopL1Bridge.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract HopL1EthToArbitrumUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    using SafeERC20 for IERC20;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    HopImplL1 internal hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15819486);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        hopBridgeImpl = new HopImplL1(
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(hopBridgeImpl);

        // Emits Event
        emit NewRouteAdded(0, address(hopBridgeImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeUSDC() public {
        address _l1bridgeAddr = 0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 90e6;
        uint256 _relayerFee = 0;
        uint256 _deadline = block.timestamp + 100000;

        uint256 amount = 100e6;
        address token = USDC;
        address[] memory routers = new address[](1);
        address[] memory tokens = new address[](1);

        routers[0] = _l1bridgeAddr;
        tokens[0] = USDC;

        vm.startPrank(owner);
        socketGateway.setApprovalForRouters(routers, tokens, true);
        vm.stopPrank();
        vm.startPrank(sender1);
        bytes memory packedBytes = bytes.concat(
            bytes4(uint32(385)),
            optimisedBridgeErc20Selector,
            bytes20(USDC),
            bytes20(_l1bridgeAddr),
            bytes20(sender1),
            bytes4(uint32(42161)),
            bytes16(uint128(amount)),
            bytes16(uint128(_amountOutMin))
        );

        // bytes memory eventData = abi.encodePacked(
        //     "hop-L1",
        //     "EthToArbitrumUSDC"
        // );

        // bytes memory impldata = abi.encodeWithSelector(
        //     hopBridgeImpl.HOP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
        //     sender1,
        //     token,
        //     _l1bridgeAddr,
        //     _relayer,
        //     42161,
        //     amount,
        //     _amountOutMin,
        //     _relayerFee,
        //     HopImplL1.HopERC20Data(_deadline, metadata)
        // );

        deal(address(token), address(sender1), amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        IERC20(token).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        address(socketGateway).call(packedBytes);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "LL-Hop-Route on Eth-Mainnet gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(token).balanceOf(sender1), 0);

        vm.stopPrank();
    }
}
