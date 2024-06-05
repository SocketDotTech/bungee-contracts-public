// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../../lib/forge-std/src/console.sol";
import "../../../../../../lib/forge-std/src/Script.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../../../SocketGatewayBaseTest.sol";
import {ISocketController} from "../../../../../../src/interfaces/ISocketController.sol";
import {ISocketGateway} from "../../../../../../src/interfaces/ISocketGateway.sol";
import {ISocketRequest} from "../../../../../../src/interfaces/ISocketRequest.sol";
import {HopImplL1} from "../../../../../../src/bridges/hop/l1/HopImplL1.sol";
import {FeesTakerController} from "../../../../../../src/controllers/FeesTakerController.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../../../../src/errors/SocketErrors.sol";
import "../../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract DeductNativeFeesTakerAndHopL1BridgeControllerTest is
    Test,
    SocketGatewayBaseTest
{
    using SafeTransferLib for ERC20;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    address constant integrator = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant feesTakerAddress =
        0x8ABF8B2353CC86aC253394bb0a9cEb030Fcf1ac6;
    address constant receiver = 0x810396ca96cc1406Ad6663E1C8f85D9c91acB89B;

    SocketGateway internal socketGateway;
    FeesTakerController feesTakerController;
    HopImplL1 hopBridgeImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16257296);
        vm.selectFork(fork);

        socketGateway = createSocketGateway();
        vm.startPrank(owner);

        hopBridgeImpl = new HopImplL1(
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(hopBridgeImpl);
        socketGateway.addRoute(route_0);

        feesTakerController = new FeesTakerController(address(socketGateway));
        socketGateway.addController(address(feesTakerController));

        vm.stopPrank();
    }

    function testNativeFeesAndBridge() public {
        uint256 amount = 303e18;
        uint256 bridgeAmount = 300e18;
        uint256 feesAmount = 3e18;
        address token = NATIVE_TOKEN_ADDRESS;

        deal(integrator, amount);
        assertEq(integrator.balance, amount);
        assertEq(address(socketGateway).balance, 0);
        assertEq(address(feesTakerAddress).balance, 0);
        assertEq(receiver.balance, 0);

        address _l1bridgeAddr = 0xb8901acB165ed027E32754E0FFe830802919727f;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 290e18;
        uint256 _relayerFee = 0;
        uint256 _deadline = block.timestamp + 100000;

        bytes memory bridgeImplData = abi.encodeWithSelector(
            hopBridgeImpl.HOP_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            _l1bridgeAddr,
            _relayer,
            42161,
            bridgeAmount,
            _amountOutMin,
            _relayerFee,
            _deadline,
            metadata
        );

        ISocketRequest.FeesTakerBridgeRequest
            memory feesBridgeRequest = ISocketRequest.FeesTakerBridgeRequest({
                feesTakerAddress: feesTakerAddress,
                feesToken: token,
                feesAmount: feesAmount,
                routeId: 513,
                bridgeRequestData: bridgeImplData
            });

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory controllerImplData = abi.encodeWithSelector(
            feesTakerController.FEES_TAKER_BRIDGE_FUNCTION_SELECTOR(),
            feesBridgeRequest
        );

        ISocketGateway.SocketControllerRequest memory socketControllerRequest;
        socketControllerRequest.controllerId = 0;
        socketControllerRequest.data = controllerImplData;

        bytes memory eventData = abi.encodePacked(
            "DeductNativeFees-Bridge-Controller"
        );

        vm.startPrank(integrator);

        socketGateway.executeController{value: amount}(
            socketControllerRequest,
            eventData
        );

        vm.stopPrank();

        assertEq(integrator.balance, 0);
        assertEq(address(socketGateway).balance, 0);
        assertEq(address(feesTakerAddress).balance, feesAmount);
        assertEq(receiver.balance, 0);
    }
}
