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

contract FeesTakerSwapERC20Test is Test, SocketGatewayBaseTest {
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

    function testDeductERC20FeesAndSwapERC20() public {
        uint256 amount = 103e6;
        uint256 swapAmount = 100e6;
        uint256 feesAmount = 3e6;
        address token = USDC;

        deal(address(token), integrator, amount);
        assertEq(ERC20(token).balanceOf(integrator), amount);

        SwapRequest memory swapRequest;

        swapRequest.id = 0;
        swapRequest.receiverAddress = recipient;
        swapRequest.amount = swapAmount;
        swapRequest.inputToken = token;
        swapRequest.toToken = NATIVE_TOKEN_ADDRESS;

        //https://api.1inch.io/v5.0/1/swap?fromTokenAddress=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&toTokenAddress=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&amount=100000000&fromAddress=0x2e234DAe75C793f67A35089C9d99245E1C58470b&slippage=1&destReceiver=0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba&disableEstimate=true
        swapRequest.data = bytes(
            hex"f78dc253000000000000000000000000cd4faec53142e37f657d7b44504de8ed13af40ba000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000125e946077e6d1200000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000140000000000000003b6d0340b4e16d0168e52d35cacd2c6185b44281ec28c9dccfee7c08"
        );

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

        assertEq(ERC20(token).balanceOf(integrator), amount);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(address(feesTakerAddress)), 0);
        assertEq(ERC20(token).balanceOf(recipient), 0);

        vm.startPrank(integrator);

        ERC20(token).safeApprove(address(socketGateway), amount);

        // Emits Event

        // assert for SocketSwapTokens Event in OneInch Swap route
        uint256 expected_Swapped_Amount = 84293282923718320;
        emit SocketSwapTokens(
            swapRequest.inputToken,
            swapRequest.toToken,
            expected_Swapped_Amount,
            swapRequest.amount,
            ONEINCH,
            recipient
        );

        socketGateway.executeController(
            socketControllerRequest,
            abi.encodePacked("TakeFees", "SwapERC20Token")
        );

        vm.stopPrank();

        assertEq(ERC20(token).balanceOf(integrator), 0);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(feesTakerAddress), feesAmount);
        assertEq(ERC20(token).balanceOf(recipient), 0);
    }
}
