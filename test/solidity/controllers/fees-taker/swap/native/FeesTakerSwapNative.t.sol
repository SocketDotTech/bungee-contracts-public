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
import {RefuelBridgeImpl} from "../../../../../../src/bridges/refuel/refuel.sol";
import {OneInchImpl} from "../../../../../../src/swap/oneinch/OneInchImpl.sol";
import {HopImplL1} from "../../../../../../src/bridges/hop/l1/HopImplL1.sol";
import {FeesTakerController} from "../../../../../../src/controllers/FeesTakerController.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../../../../src/errors/SocketErrors.sol";
import "../../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract FeesTakerSwapNative is Test, SocketGatewayBaseTest {
    using SafeTransferLib for ERC20;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant integrator = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant feesTakerAddress =
        0x8ABF8B2353CC86aC253394bb0a9cEb030Fcf1ac6;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address public immutable ONEINCH_AGGREGATOR =
        0x1111111254EEB25477B68fb85Ed929f73A960582;

    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    SocketGateway internal socketGateway;
    FeesTakerController feesTakerController;
    OneInchImpl internal oneInchImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16219787);
        vm.selectFork(fork);

        socketGateway = createSocketGateway();
        vm.startPrank(owner);

        oneInchImpl = new OneInchImpl(
            ONEINCH_AGGREGATOR,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(oneInchImpl);
        socketGateway.addRoute(route_0);

        feesTakerController = new FeesTakerController(address(socketGateway));
        socketGateway.addController(address(feesTakerController));

        vm.stopPrank();
    }

    function testDeductERC20FeesAndSwapNative() public {
        uint256 feesAmount = 3e6;
        address token = USDC;

        deal(address(token), integrator, feesAmount);
        assertEq(ERC20(token).balanceOf(integrator), feesAmount);

        SwapRequest memory swapRequest;
        swapRequest.id = 0;
        swapRequest.receiverAddress = recipient;
        swapRequest.amount = 10000000000000000;
        swapRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        swapRequest.toToken = token;
        swapRequest.data = bytes(
            hex"f78dc2530000000000000000000000008657ab84a5b7fc75b9327d6248ca398fa25d67120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000b1e15500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000180000000000000003b5dc1003926a168c11a816e10c13977f75f488bfffe88e4cfee7c08"
        );

        //fund integrator with the native balance to be swapped to ERC20
        deal(integrator, swapRequest.amount);

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory swapImplData = abi.encodeWithSelector(
            oneInchImpl.SWAP_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.receiverAddress,
            swapRequest.data
        );

        ISocketRequest.FeesTakerSwapRequest
            memory feesSwapRequest = ISocketRequest.FeesTakerSwapRequest({
                feesTakerAddress: feesTakerAddress,
                feesToken: token,
                feesAmount: feesAmount,
                routeId: 513,
                swapRequestData: swapImplData
            });

        bytes memory controllerImplData = abi.encodeWithSelector(
            feesTakerController.FEES_TAKER_SWAP_FUNCTION_SELECTOR(),
            feesSwapRequest
        );

        ISocketGateway.SocketControllerRequest memory socketControllerRequest;
        socketControllerRequest.controllerId = 0;
        socketControllerRequest.data = controllerImplData;

        assertEq(ERC20(token).balanceOf(integrator), feesAmount);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(address(feesTakerAddress)), 0);
        assertEq(ERC20(token).balanceOf(recipient), 0);
        assertEq(integrator.balance, swapRequest.amount);

        vm.startPrank(integrator);

        ERC20(token).safeApprove(address(socketGateway), feesAmount);

        // Emits Event

        // assert for SocketSwapTokens Event in OneInch Swap route
        uint256 expected_Swapped_Amount = 11775311;
        emit SocketSwapTokens(
            swapRequest.inputToken,
            swapRequest.toToken,
            expected_Swapped_Amount,
            swapRequest.amount,
            ONEINCH,
            recipient
        );

        socketGateway.executeController{value: swapRequest.amount}(
            socketControllerRequest,
            abi.encodePacked("TakeFees", "SwapNativeToken")
        );

        vm.stopPrank();

        assertEq(ERC20(token).balanceOf(integrator), 0);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(feesTakerAddress), feesAmount);
        assertEq(ERC20(token).balanceOf(recipient), 0);
        assertEq(integrator.balance, 0);
        assertEq(recipient.balance, 0);
        assertEq(address(socketGateway).balance, 0);
    }
}
