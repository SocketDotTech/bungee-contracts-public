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

contract StargateL2PolygonToOptimismUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //reference txn on Polygon for USDC bridging to EtherLite
    //https://polygonscan.com/tx/0x343a9b6cc9d4c7003811256873f6047a0c4399f09bb5ca15d5048e9bb229f4e0

    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant router = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
    address constant routerETH = 0xbf22f0f184bCcbeA268dF387a49fF5238dD23E40;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    StargateImplL2 internal stargateImpl;

    struct StargateTestLocalVars {
        uint16 stargateDstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt;
        uint256 destinationGasLimit;
        bytes destinationPayload;
    }

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 37137945);
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
        emit NewRouteAdded(0, address(stargateImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeUSDC() public {
        uint256 optionalValue = 0;
        address senderAddress = sender1;
        uint256 amount = 300e6;
        uint256 value = 1e18;
        address token = USDC;
        bytes memory eventData = abi.encodePacked(
            "stargate-l2",
            "polygon-optimism",
            "USDC"
        );

        StargateTestLocalVars memory stargateTestLocalVars;
        stargateTestLocalVars.stargateDstChainId = uint16(111);
        stargateTestLocalVars.srcPoolId = 1;
        stargateTestLocalVars.dstPoolId = 1;
        stargateTestLocalVars.minReceivedAmt = 290e6;
        stargateTestLocalVars.destinationGasLimit = 0;
        stargateTestLocalVars.destinationPayload = EMPTY_DATA;
        bytes32 metadata = 0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;

        // receiverAddress, token, senderAddress, amount, value, srcPoolId, dstPoolId, minReceivedAmt, optionalValue, destinationGasLimit, stargateDstChainId, destinationPayload
        bytes memory impldata = abi.encodeWithSelector(
            stargateImpl.STARGATE_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            USDC,
            senderAddress,
            receiver,
            amount,
            value,
            optionalValue,
            StargateImplL2.StargateBridgeExtraData(
                stargateTestLocalVars.srcPoolId,
                stargateTestLocalVars.dstPoolId,
                stargateTestLocalVars.destinationGasLimit,
                stargateTestLocalVars.minReceivedAmt,
                metadata,
                stargateTestLocalVars.destinationPayload,
                stargateTestLocalVars.stargateDstChainId
            )
        );

        deal(sender1, value);
        deal(token, address(sender1), amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        vm.startPrank(sender1);

        IERC20(token).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: value}(513, impldata, eventData);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(token).balanceOf(sender1), 0);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        console.log(
            "Stargate-L2-Router gas-cost for USDC-Bridging from Polygon-Mainnet to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
