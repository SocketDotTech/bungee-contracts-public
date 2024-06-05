// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {ZkSyncBridgeImpl} from "../../../../src/bridges/zksync/ZkSyncBridgeImpl.sol";
import "../../../../src/bridges/zksync/interfaces/IZkSyncL1ERC20Bridge.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract ZkSyncBridgeL1L2USDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    using SafeERC20 for IERC20;

    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0x17Ac6982b9CeAfbB36ee486722E8EB0f30b1E97D;
    address constant l1ERC20BridgeAddress =
        0x57891966931Eb4Bb6FB81430E6cE0A03AAbDe063;
    address constant mailboxFacetProxyAddress =
        0x32400084C286CF3E17e7B677ea9583e60a000324;

    ZkSyncBridgeImpl internal zkSyncBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 17499457);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        zkSyncBridgeImpl = new ZkSyncBridgeImpl(
            l1ERC20BridgeAddress,
            mailboxFacetProxyAddress,
            address(socketGateway),
            address(socketGateway)
        );

        address route_0 = address(zkSyncBridgeImpl);

        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeUSDC() public {
        vm.startPrank(sender1);

        uint256 amount = 100e6;
        address token = USDC;
        uint256 fees = 1e18;

        deal(sender1, fees);

        bytes memory eventData = abi.encodePacked("zkSync-L1Bridge", "USDC");

        bytes memory impldata = abi.encodeWithSelector(
            zkSyncBridgeImpl.ZKSYNC_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            fees,
            eventData,
            receiver,
            USDC,
            324,
            800000,
            800
        );

        deal(address(token), address(sender1), amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        IERC20(token).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: fees}(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "LL-ZkSync-Route on Eth-Mainnet gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(token).balanceOf(sender1), 0);

        vm.stopPrank();
    }
}
