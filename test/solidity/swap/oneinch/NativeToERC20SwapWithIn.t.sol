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

contract NativeToERC20SwapWithInInOneInchTest is Test, SocketGatewayBaseTest {
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
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16447433);
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

    function testSwapWithInNativeToERC20() public {
        SwapRequest memory swapRequest;

        swapRequest.id = 0;
        swapRequest.receiverAddress = address(socketGateway);
        swapRequest.amount = 10000000000000000;
        swapRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        swapRequest.toToken = USDC;
        bytes memory eventData = abi.encodePacked(
            "oneinch",
            "native-erc20",
            "swapWithIn"
        );

        // socketGatewayAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f to be used as destReceiver
        //https://api.1inch.io/v5.0/1/swap?fromTokenAddress=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&toTokenAddress=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&amount=10000000000000000&fromAddress=0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f&slippage=1&disableEstimate=true
        swapRequest.data = bytes(
            hex"0502b1c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000e9fb910000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340397ff1542f962076d0bfe58ea045ffa2d347aca0cfee7c08"
        );

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            OneInch.SWAP_WITHIN_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
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

        console.log(
            "OneInch-Swap-WithIn Native to ERC20 -> GasUsed:  ",
            gasStockbeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
