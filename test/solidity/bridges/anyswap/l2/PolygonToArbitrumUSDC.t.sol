// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {AnyswapL2Impl} from "../../../../../src/bridges/anyswap-router-v4/l2/Anyswap.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract AnyswapPolygonToArbitrumUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant ANY_SWAP_USDC = 0xd69b31c3225728CC57ddaf9be532a4ee1620Be51;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant router = 0x4f3Aff3A747fCADe12598081e80c6605A8be192F;

    AnyswapL2Impl internal anyswapL2Impl;

    function setUp() public {
        //https://polygonscan.com/tx/0xdc031c883bfd1bca7f4bc56312fead0b6acfaf3130910e81e12134df29fbe1a5
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 34236074);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        anyswapL2Impl = new AnyswapL2Impl(
            router,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(anyswapL2Impl);

        // Emits Event
        emit NewRouteAdded(0, address(anyswapL2Impl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeUSDC() public {
        uint256 amount = 100e6;
        uint256 toChainId = 42161;
        address token = USDC;
        bytes memory eventData = abi.encodePacked(
            "Anyswap-L2",
            "PolygonToArbitrumUSDC"
        );

        bytes memory impldata = abi.encodeWithSelector(
            anyswapL2Impl.ANYSWAP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            toChainId,
            metadata,
            receiver,
            token,
            ANY_SWAP_USDC
        );

        deal(address(token), address(sender1), amount);

        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(token).balanceOf(receiver), 0);

        vm.startPrank(sender1);

        IERC20(token).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(token).balanceOf(sender1), 0);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(token).balanceOf(receiver), 0);

        console.log(
            "AnySwap-L2-Bridge-Router GasCost from Polygon to Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
