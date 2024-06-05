// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {NativeOptimismImpl} from "../../../../src/bridges/optimism/l1/NativeOptimism.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract OptimismBridgeUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant optSNX = 0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4;
    address constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address constant sUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address constant optSusd = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;
    address constant optUSDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    bytes32 constant zeroBytes32 =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant synthCurrencyKey =
        0x7355534400000000000000000000000000000000000000000000000000000000;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;

    address constant customUSDCBridge =
        0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address constant customSnxBridge =
        0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F;
    address constant customSynthAddress =
        0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F;
    uint256 constant newInterfaceId = 1;
    uint256 constant oldInterfaceId = 2;
    uint256 constant synthInterfaceId = 3;
    NativeOptimismImpl internal nativeOptimismImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15876510);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        nativeOptimismImpl = new NativeOptimismImpl(
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(nativeOptimismImpl);

        // Emits Event
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testSendUSDCOnL1BridgeRequest() public {
        address token = USDC;
        address _customBridgeAddress = customUSDCBridge;
        address _l2Token = optUSDC;
        uint256 bridgingAmount = 1000e6;
        uint256 _interfaceId = newInterfaceId;
        uint32 _l2Gas = 2000000;
        bytes32 _currencyKey = zeroBytes32;
        bytes memory _data = "0x";
        bytes memory eventData = abi.encodePacked("native-optimism", "USDC");

        bytes memory impldata = abi.encodeWithSelector(
            nativeOptimismImpl
                .NATIVE_OPTIMISM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            token,
            recipient,
            _customBridgeAddress,
            _l2Gas,
            NativeOptimismImpl.OptimismERC20Data(_currencyKey, metadata),
            bridgingAmount,
            _interfaceId,
            _l2Token,
            _data
        );

        deal(address(USDC), address(sender1), bridgingAmount);
        assertEq(IERC20(USDC).balanceOf(sender1), bridgingAmount);

        vm.startPrank(sender1);

        IERC20(USDC).approve(address(socketGateway), bridgingAmount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(sender1), 0);

        console.log(
            "NativeOptimism on Eth-Mainnet gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
