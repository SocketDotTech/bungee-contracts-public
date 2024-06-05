// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {StargateImplL2} from "../../../../../src/bridges/stargate/l2/Stargate.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract StargateL2ArbitrumToOptimismNativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    address constant router = 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;
    address constant routerETH = 0xbf22f0f184bCcbeA268dF387a49fF5238dD23E40;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    StargateImplL2 internal stargateImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ARBITRUM_RPC"), 52232424);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        stargateImpl = new StargateImplL2(
            router,
            routerETH,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(stargateImpl);

        // Emits Event
        emit NewRouteAdded(0, route_0);
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeNative() public {
        uint256 minReceivedAmt = 1e16;
        uint256 optionalValue = 1e16;
        uint16 stargateDstChainId = uint16(111);
        address senderAddress = sender1;
        uint256 amount = 1e18;
        bytes memory eventData = abi.encodePacked(
            "stargate-l2",
            "arbitrum-optimism",
            "Native"
        );

        bytes memory impldata = abi.encodeWithSelector(
            stargateImpl.STARGATE_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            senderAddress,
            stargateDstChainId,
            amount,
            minReceivedAmt,
            optionalValue,
            metadata
        );

        deal(sender1, amount + optionalValue);
        assertEq(sender1.balance, amount + optionalValue);
        assertEq(address(socketGateway).balance, 0);

        vm.startPrank(sender1);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount + optionalValue}(
            513,
            impldata,
            eventData
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(address(socketGateway).balance, 0);

        console.log(
            "Stargate-L2-Router gas cost for Native-Bridge from Arbitrum to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
