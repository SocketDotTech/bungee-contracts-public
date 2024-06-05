// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {AnyswapImplL1} from "../../../../../src/bridges/anyswap-router-v4/l1/Anyswap.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract EthToArbitrumAnyswapUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ANY_SWAP_USDC = 0x7EA2be2df7BA6E54B1A9C70676f668455E329d29;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant router = 0x6b7a87899490EcE95443e979cA9485CBE7E71522;

    AnyswapImplL1 internal anyswapImplL1;

    function setUp() public {
        //https://etherscan.io/tx/0xc783cf4a60e68ba453f8786a96e0a233de8a4dcbb15bcf4c7c4a0f7738fbb8f1
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15588208);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        anyswapImplL1 = new AnyswapImplL1(
            router,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(anyswapImplL1);

        // Emits Event
        emit NewRouteAdded(0, address(anyswapImplL1));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeUSDC() public {
        uint256 amount = 100e6;
        address token = USDC;
        uint256 toChainId = 42161;
        bytes memory eventData = abi.encodePacked(
            "Anyswap-L1",
            "EthToArbitrumUSDC"
        );

        bytes memory impldata = abi.encodeWithSelector(
            anyswapImplL1.ANYSWAP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
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

        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(token).balanceOf(sender1), 0);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        console.log(
            "AnySwap-L1-Bridge-Router USDC from Ethereum to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
