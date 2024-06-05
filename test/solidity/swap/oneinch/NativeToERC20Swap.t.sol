// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {OneInchImpl} from "../../../../src/swap/oneinch/OneInchImpl.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";

contract NativeToERC20OneInchTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
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

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //ETH Mainnet
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    OneInchImpl internal OneInch;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16219787);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        OneInch = new OneInchImpl(
            0x1111111254EEB25477B68fb85Ed929f73A960582,
            address(socketGateway),
            address(socketGateway)
        );
        vm.startPrank(owner);

        address route_0 = address(OneInch);

        // Emits Event
        emit NewRouteAdded(0, route_0);

        socketGateway.addRoute(route_0);

        vm.stopPrank();
    }

    function testSwapNativeToERC20() public {
        SwapRequest memory swapRequest;

        swapRequest.id = 0;
        swapRequest
            .receiverAddress = 0x8657AB84A5B7Fc75B9327d6248cA398FA25D6712;
        swapRequest.amount = 10000000000000000;
        swapRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        swapRequest.toToken = USDC;
        swapRequest.data = bytes(
            hex"f78dc2530000000000000000000000008657ab84a5b7fc75b9327d6248ca398fa25d67120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000b1e15500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000180000000000000003b5dc1003926a168c11a816e10c13977f75f488bfffe88e4cfee7c08"
        );
        bytes memory eventData = abi.encodePacked(
            "oneinch",
            "native-erc20",
            "swap"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            OneInch.SWAP_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.receiverAddress,
            swapRequest.data
        );

        deal(sender1, swapRequest.amount);
        assertEq(sender1.balance, swapRequest.amount);
        assertEq(address(socketGateway).balance, 0);
        assertEq(
            IERC20(swapRequest.toToken).balanceOf(swapRequest.receiverAddress),
            0
        );

        vm.startPrank(sender1);

        deal(sender1, swapRequest.amount);

        uint256 gasStockbeforeSwap = gasleft();

        bytes memory swapResponseData = socketGateway.executeRoute{
            value: swapRequest.amount
        }(513, impldata, eventData);

        uint256 gasStockAfterSwap = gasleft();

        uint256 swappedAmount = abi.decode(swapResponseData, (uint256));
        uint256 erc20BalanceOfReceiver = IERC20(swapRequest.toToken).balanceOf(
            swapRequest.receiverAddress
        );
        assertEq(erc20BalanceOfReceiver, swappedAmount);

        assertEq(sender1.balance, 0);
        assertEq(IERC20(swapRequest.toToken).balanceOf(sender1), 0);
        assertEq(address(socketGateway).balance, 0);
        assertEq(
            IERC20(swapRequest.toToken).balanceOf(address(socketGateway)),
            0
        );

        console.log(
            "OneInch-Swap Native to ERC20 -> GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
