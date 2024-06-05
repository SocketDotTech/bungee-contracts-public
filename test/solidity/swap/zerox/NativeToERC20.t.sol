// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {ZeroXSwapImpl} from "../../../../src/swap/zerox/ZeroXSwapImpl.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {ISocketRequest} from "../../../../src/interfaces/ISocketRequest.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract NativeToERC20Test is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }
    //ETH Mainnet

    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant zeroXExchangeProxy =
        0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    ZeroXSwapImpl internal zeroXSwapImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16219787);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        zeroXSwapImpl = new ZeroXSwapImpl(
            zeroXExchangeProxy,
            address(socketGateway),
            address(socketGateway)
        );

        vm.startPrank(owner);

        address route_0 = address(zeroXSwapImpl);
        // Emits Event
        emit NewRouteAdded(0, route_0);
        socketGateway.addRoute(route_0);

        vm.stopPrank();
    }

    // swap 100 USDC -> ETH
    function testSwapNativeToERC20() public {
        SwapRequest memory swapRequest;

        swapRequest.id = 0;
        swapRequest
            .receiverAddress = 0x8657AB84A5B7Fc75B9327d6248cA398FA25D6712;
        swapRequest.amount = 1e18;
        swapRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        swapRequest.toToken = USDC;
        bytes memory eventData = abi.encodePacked("zerox", "native-erc20");

        //https://api.0x.org/swap/v1/quote?buyToken=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&sellToken=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&sellAmount=1000000000000000000&slippagePercentage=1&skipValidation=true
        bytes memory zeroxExtraData = bytes(
            hex"3598d8ab000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f4a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000869584cd000000000000000000000000100000000000000000000000000000000000001100000000000000000000000000000000000000000000008a698f25b163a4a245"
        );

        swapRequest.data = abi.encode(zeroxExtraData);

        //sequence of arguments for implData: from, fromToken, toToken, amount, receiverAddress, _data
        bytes memory impldata = abi.encodeWithSelector(
            zeroXSwapImpl.SWAP_FUNCTION_SELECTOR(),
            swapRequest.inputToken,
            swapRequest.toToken,
            swapRequest.amount,
            swapRequest.receiverAddress,
            swapRequest.data
        );

        deal(sender1, swapRequest.amount);
        assertEq(sender1.balance, swapRequest.amount);
        assertEq(address(socketGateway).balance, 0);

        vm.startPrank(sender1);

        uint256 gasStockBeforeSwap = gasleft();

        bytes memory swapResponseData = socketGateway.executeRoute{
            value: swapRequest.amount
        }(513, impldata, eventData);

        uint256 gasStockAfterSwap = gasleft();

        uint256 swappedAmount = abi.decode(swapResponseData, (uint256));

        uint256 erc20BalanceOfReceiver = IERC20(swapRequest.toToken).balanceOf(
            swapRequest.receiverAddress
        );
        assertEq(erc20BalanceOfReceiver, swappedAmount);

        console.log(address(socketGateway));
        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "Zerox-Swap Native to ERC20 -> GasUsed:  ",
            gasStockBeforeSwap - gasStockAfterSwap
        );

        vm.stopPrank();
    }
}
