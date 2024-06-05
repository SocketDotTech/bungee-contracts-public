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
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant optDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    bytes32 constant zeroBytes32 =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;

    address constant customDAIBridge =
        0x10E6593CDda8c58a1d0f14C5164B376352a55f2F;
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
        address token = DAI;
        address _customBridgeAddress = customDAIBridge;
        address _l2Token = optDAI;
        uint256 bridgingAmount = 100e18;
        uint256 _interfaceId = newInterfaceId;
        uint32 _l2Gas = 2000000;
        bytes32 _currencyKey = zeroBytes32;
        bytes memory _data = "0x";
        bytes memory eventData = abi.encodePacked("native-optimism", "DAI");

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

        deal(address(token), address(sender1), bridgingAmount);
        assertEq(IERC20(token).balanceOf(sender1), bridgingAmount);

        vm.startPrank(sender1);

        IERC20(token).approve(address(socketGateway), bridgingAmount);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(token).balanceOf(sender1), 0);

        console.log(
            "NativeOptimism on Eth-Mainnet gas-cost for DAI-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
