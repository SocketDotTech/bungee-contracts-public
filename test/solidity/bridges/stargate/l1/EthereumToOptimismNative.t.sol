// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {StargateImplL1} from "../../../../../src/bridges/stargate/l1/Stargate.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract StargateL1EthereumToOptimismNativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet to Ethereum-Lite reference transaction
    //https://etherscan.io/tx/0x7d23443e36f95f411e89002cc28497be5a0447a39765317ded4fe7d51a290629

    address constant router = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    address constant routerETH = 0x150f94B44927F078737562f0fcF3C95c01Cc2376;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    StargateImplL1 internal stargateImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15588208);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        stargateImpl = new StargateImplL1(
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
        uint256 stargateDstChainId = 111;
        address senderAddress = sender1;
        uint256 amount = 1e18;
        bytes memory eventData = abi.encodePacked("stargate-l1", "NATIVE");

        // receiverAddress, token, senderAddress, amount, value, srcPoolId, dstPoolId, minReceivedAmt, optionalValue, destinationGasLimit, stargateDstChainId, destinationPayload
        bytes memory impldata = abi.encodeWithSelector(
            stargateImpl.STARGATE_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            senderAddress,
            uint16(stargateDstChainId),
            amount,
            minReceivedAmt,
            optionalValue,
            metadata
        );

        vm.startPrank(sender1);
        deal(sender1, amount + optionalValue);
        console.log("sender1.balance", sender1.balance);
        console.log(
            "address(socketGateway).balance",
            address(socketGateway).balance,
            address(socketGateway)
        );
        console.log("receiver.balance", receiver.balance);
        assertEq(sender1.balance, amount + optionalValue);
        assertEq(receiver.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount + optionalValue}(
            513,
            impldata,
            eventData
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(receiver.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "Stargate-L1-Router gas-cost for Native Bridging to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
