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

contract OptimismBridgeSNXTest is Test, SocketGatewayBaseTest {
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
    address constant sender1 = 0xAc86855865CbF31c8f9FBB68C749AD5Bd72802e3;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    bytes32 constant zeroBytes32 =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant synthCurrencyKey =
        0x7355534400000000000000000000000000000000000000000000000000000000;

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
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"));
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

    function testSendSNXOnL1BridgeRequest() public {
        address token = SNX;
        address _customBridgeAddress = customSnxBridge;
        address _l2Token = optSNX;
        uint256 bridgingAmount = 1000e18;
        uint256 _interfaceId = oldInterfaceId;
        uint32 _l2Gas = 2000000;
        bytes memory _data = "0x";
        bytes memory eventData = abi.encodePacked("native-optimism", "SNX");

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory impldata = abi.encodeWithSelector(
            nativeOptimismImpl
                .NATIVE_OPTIMISM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            token,
            recipient,
            _customBridgeAddress,
            _l2Gas,
            NativeOptimismImpl.OptimismERC20Data(synthCurrencyKey, metadata),
            bridgingAmount,
            _interfaceId,
            _l2Token,
            _data
        );

        vm.startPrank(sender1);

        IERC20(SNX).approve(address(socketGateway), bridgingAmount);

        uint256 SNXBalance_BeforeBridging = IERC20(SNX).balanceOf(sender1);

        assertEq(IERC20(SNX).balanceOf(address(socketGateway)), 0);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        //assert that SNX balance of SocketGateway should be 0
        assertEq(IERC20(SNX).balanceOf(address(socketGateway)), 0);

        //assert that SNX balance of Sender should reduce by bridgedAmount
        uint256 SNXBalance_AfterBridging = IERC20(SNX).balanceOf(sender1);
        assertEq(
            SNXBalance_BeforeBridging - SNXBalance_AfterBridging,
            bridgingAmount
        );

        console.log(
            "NativeOptimism on Eth-Mainnet gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
