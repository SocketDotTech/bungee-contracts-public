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
import {NativeOptimismImpl} from "../../../../../../src/bridges/optimism/l1/NativeOptimism.sol";
import {FeesTakerController} from "../../../../../../src/controllers/FeesTakerController.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OnlySocketGatewayOwner, OnlyOwner} from "../../../../../../src/errors/SocketErrors.sol";
import "../../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract DeductERC20FeesTakerAndOptimismBridgeControllerTest is
    Test,
    SocketGatewayBaseTest
{
    using SafeTransferLib for ERC20;
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant SNXWhale = 0xAc86855865CbF31c8f9FBB68C749AD5Bd72802e3;
    address constant integrator = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant feesTakerAddress =
        0x8ABF8B2353CC86aC253394bb0a9cEb030Fcf1ac6;
    address constant receiver = 0x810396ca96cc1406Ad6663E1C8f85D9c91acB89B;

    SocketGateway internal socketGateway;
    FeesTakerController feesTakerController;

    address constant optSNX = 0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4;
    address constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address constant sUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address constant optSusd = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;
    address constant optUSDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
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
        vm.startPrank(owner);

        nativeOptimismImpl = new NativeOptimismImpl(
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(nativeOptimismImpl);
        socketGateway.addRoute(route_0);

        feesTakerController = new FeesTakerController(address(socketGateway));

        socketGateway.addController(address(feesTakerController));

        vm.stopPrank();
    }

    function testERC20FeesAndBridge() public {
        uint256 amount = 303e18;
        uint256 bridgeAmount = 300e18;
        uint256 feesAmount = 3e18;
        address token = SNX;

        vm.startPrank(SNXWhale);
        ERC20(token).safeTransfer(integrator, amount);
        vm.stopPrank();

        assertEq(ERC20(token).balanceOf(integrator), amount);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(feesTakerAddress), 0);
        assertEq(ERC20(token).balanceOf(receiver), 0);

        address _customBridgeAddress = customSnxBridge;
        address _l2Token = optSNX;
        uint256 _interfaceId = oldInterfaceId;
        uint32 _l2Gas = 2000000;
        bytes memory _data = "0x";

        //sequence of arguments for implData: _amount, _from, _receiverAddress, _token, _toChainId, value, _data
        bytes memory bridgeImplData = abi.encodeWithSelector(
            nativeOptimismImpl
                .NATIVE_OPTIMISM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            token,
            receiver,
            _customBridgeAddress,
            _l2Gas,
            NativeOptimismImpl.OptimismERC20Data(synthCurrencyKey, metadata),
            bridgeAmount,
            _interfaceId,
            _l2Token,
            _data
        );

        ISocketRequest.FeesTakerBridgeRequest
            memory feesTakerBridgeRequest = ISocketRequest
                .FeesTakerBridgeRequest({
                    feesTakerAddress: feesTakerAddress,
                    feesToken: token,
                    feesAmount: feesAmount,
                    routeId: 513,
                    bridgeRequestData: bridgeImplData
                });

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory controllerImplData = abi.encodeWithSelector(
            feesTakerController.FEES_TAKER_BRIDGE_FUNCTION_SELECTOR(),
            feesTakerBridgeRequest
        );

        ISocketGateway.SocketControllerRequest memory socketControllerRequest;
        socketControllerRequest.controllerId = 0;
        socketControllerRequest.data = controllerImplData;

        bytes memory eventData = abi.encodePacked(
            "DeductFees-Bridge-Controller"
        );

        vm.startPrank(integrator);

        ERC20(token).safeApprove(address(socketGateway), amount);

        socketGateway.executeController(socketControllerRequest, eventData);

        vm.stopPrank();

        assertEq(ERC20(token).balanceOf(integrator), 0);
        assertEq(ERC20(token).balanceOf(receiver), 0);
        assertEq(ERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(ERC20(token).balanceOf(feesTakerAddress), feesAmount);
    }
}
