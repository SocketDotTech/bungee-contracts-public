// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {AcrossImpl} from "../../../../src/bridges/across/AcrossV3.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract EthToOptimismUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant depositor = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant recipient = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant spokePoolAddress =
        0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address constant inputToken = USDC;
    address constant outputToken = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    uint256 destinationChainId = 10;
    address constant exclusiveRelayer = ZERO_ADDRESS;
    uint32 fillDeadline = 0;
    uint32 exclusivityDeadline = 0;
    uint256 amount = 50000000;
    uint256 outputAmount = 50000000;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct AcrossBridgeData {
        address[] senderReceiverAddresses; // 0 - sender, 1 - receiver
        address[] inputOutputTokens; // 0 - input token, 1 - output token
        uint256[] outputAmountToChainIdArray; // 0 -output amount, 1 - tochainId
        uint32[] quoteAndDeadlineTimeStamps; // 0 - quoteTimestamp, 1 - fillDeadline
        bytes32 metadata;
    }

    AcrossImpl internal acrossImpl;

    function setUp() public {
        //https://etherscan.io/tx/0x2335e1ed11fb5d179283f133dfaa9e51c5bf998b8b4cc84f357c18588c41db4a
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 19795991);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        acrossImpl = new AcrossImpl(
            spokePoolAddress,
            WETH,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(acrossImpl);
        address[] memory routers = new address[](1);
        address[] memory tokens = new address[](1);
        routers[0] = spokePoolAddress;
        tokens[0] = USDC;

        vm.startPrank(owner);
        socketGateway.setApprovalForRouters(routers, tokens, true);
        vm.stopPrank();
        // Emits Event
        emit NewRouteAdded(0, address(acrossImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testSendUSDCToOptimism() public {
        deal(address(USDC), address(depositor), amount);
        // assertEq(IERC20(USDC).balanceOf(depositor), amount);
        // assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        // assertEq(IERC20(USDC).balanceOf(recipient), 0);
        address[] memory senderReceiverAddresses = new address[](2);
        senderReceiverAddresses[0] = depositor;
        senderReceiverAddresses[1] = recipient;

        address[] memory inputOutputTokens = new address[](2);
        inputOutputTokens[0] = inputToken;
        inputOutputTokens[1] = outputToken;

        uint256[] memory outputAmountToChainIdArray = new uint256[](2);
        outputAmountToChainIdArray[0] = outputAmount;
        outputAmountToChainIdArray[1] = destinationChainId;

        uint32 quoteTimestamp = uint32(block.timestamp);

        uint32[] memory quoteAndDeadlineTimeStamps = new uint32[](2);
        quoteAndDeadlineTimeStamps[0] = quoteTimestamp;
        quoteAndDeadlineTimeStamps[1] = quoteTimestamp + 28800;

        vm.startPrank(depositor);

        IERC20(USDC).approve(address(socketGateway), amount);

        bytes memory impldata = abi.encodeWithSelector(
            acrossImpl.ACROSS_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            amount,
            AcrossBridgeData(
                senderReceiverAddresses,
                inputOutputTokens,
                outputAmountToChainIdArray,
                quoteAndDeadlineTimeStamps,
                metadata
            )
        );

        // Emits Event
        emit SocketBridge(amount, USDC, 10, ACROSS, depositor, recipient);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        // assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        // assertEq(IERC20(USDC).balanceOf(depositor), 0);
        // assertEq(IERC20(USDC).balanceOf(recipient), 0);

        console.log(
            "AcrossBridge-Router gas-cost to bridge USDC ETH to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
