// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../SocketGatewayBaseTest.sol";
import {HopImplL1V2 as HopImplL1} from "../../../../../src/bridges/hop/l1/HopImplL1V2.sol";
import {ISocketRoute} from "../../../../../src/interfaces/ISocketRoute.sol";

contract HopL1EthToArbitrumNativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
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

    function testBridgeNative() public {
        vm.startPrank(sender1);

        address _l1bridgeAddr = 0xb8901acB165ed027E32754E0FFe830802919727f;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 0;
        uint256 _relayerFee = 0;
        uint256 _deadline = 0;
        uint256 amount = 1e18;
        bytes memory eventData = abi.encodePacked(
            "hop-L1",
            "EthToArbitrumNative"
        );

        bytes memory packedBytes = bytes.concat(
            bytes4(uint32(385)),
            optimisedBridgeNativeSelector,
            bytes20(_l1bridgeAddr),
            bytes4(uint32(42161)),
            bytes20(sender1),
            bytes16(uint128(_amountOutMin))
        );

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory impldata = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            sender1,
            _l1bridgeAddr,
            _relayer,
            42161,
            amount,
            _amountOutMin,
            _relayerFee,
            _deadline,
            metadata
        );

        deal(sender1, amount);

        uint256 gasStockBeforeBridge = gasleft();

        // socketGateway.executeRoute{value: amount}(513, impldata, eventData);
        address(socketGateway).call{value: amount}(packedBytes);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "HopL1 on Eth-Mainnet gas-cost for Native-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
