// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {AcrossImpl} from "../../../../src/bridges/across/Across.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract EthToOptimismUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant spokePoolAddress =
        0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    AcrossImpl internal acrossImpl;

    function setUp() public {
        //https://etherscan.io/tx/0x2335e1ed11fb5d179283f133dfaa9e51c5bf998b8b4cc84f357c18588c41db4a
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 17152644);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        acrossImpl = new AcrossImpl(
            spokePoolAddress,
            WETH,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(acrossImpl);
        address[] memory routers = new address[](1);
        address[] memory tokens = new address[](1);
        routers[0] = spokePoolAddress;
        tokens[0] = USDC;

        vm.startPrank(owner);
        socketGateway.setApprovalForRouters(routers, tokens, true);
        vm.stopPrank();
        // Emits Event
        emit NewRouteAdded(0, address(acrossImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testSendUSDCToOptimism() public {
        uint64 _relayerFeePct = 0;
        uint32 _quoteTimestamp = uint32(block.timestamp);
        uint256 amount = 100e6;
        bytes memory eventData = abi.encodePacked(
            "Across",
            "EthToOptimismUSDC"
        );

        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(recipient), 0);

        vm.startPrank(sender1);

        IERC20(USDC).approve(address(socketGateway), amount);

        bytes memory impldata = abi.encodeWithSelector(
            acrossImpl.ACROSS_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            10,
            metadata,
            recipient,
            USDC,
            _quoteTimestamp,
            _relayerFeePct
        );

        // Emits Event
        emit SocketBridge(amount, USDC, 10, ACROSS, sender1, recipient);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(sender1), 0);
        assertEq(IERC20(USDC).balanceOf(recipient), 0);

        console.log(
            "AcrossBridge-Router gas-cost to bridge USDC ETH to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
