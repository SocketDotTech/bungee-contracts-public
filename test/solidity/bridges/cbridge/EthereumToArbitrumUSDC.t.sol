// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {CelerImpl} from "../../../../src/bridges/cbridge/CelerImpl.sol";
import {CelerStorageWrapper} from "../../../../src/bridges/cbridge/CelerStorageWrapper.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";
import {TransferIdExists} from "../../../../src/errors/SocketErrors.sol";

contract CelerEthereumToBinanceUSDCTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0x2FA81527389929Ae9FD0f9ACa9e16Cba37D3EeA1;
    address constant CELER_BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    address constant WETH_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    CelerImpl internal celerImpl;
    CelerStorageWrapper internal celerStorageWrapper;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 16227237);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        celerStorageWrapper = new CelerStorageWrapper(address(socketGateway));
        celerImpl = new CelerImpl(
            CELER_BRIDGE,
            WETH_ADDRESS,
            address(celerStorageWrapper),
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(celerImpl);

        // Emits Event
        emit NewRouteAdded(0, address(celerImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testBridgeUSDC() public {
        uint64 nonce = uint64(block.timestamp);
        uint32 maxSlippage = 5000;
        uint256 amount = 100000000;
        uint256 toChainId = 42161;
        bytes memory eventData = abi.encodePacked(
            "cbridge",
            "EthToArbitrumUSDC"
        );

        //sequence of arguments for implData: _amount, _receiverAddress, _token, _toChainId, value, _data
        bytes memory impldata = abi.encodeWithSelector(
            celerImpl.CELER_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            USDC,
            amount,
            metadata,
            uint64(toChainId),
            nonce,
            maxSlippage
        );

        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        vm.startPrank(sender1);

        IERC20(USDC).approve(address(socketGateway), amount);

        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(513, impldata);

        uint256 gasStockAfterBridge = gasleft();

        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(socketGateway),
                receiver,
                USDC,
                amount,
                uint64(toChainId),
                nonce,
                uint64(block.chainid)
            )
        );

        address storedAddress = celerStorageWrapper.getAddressFromTransferId(
            transferId
        );
        assertEq(storedAddress, sender1);

        assertEq(IERC20(USDC).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(USDC).balanceOf(receiver), 0);
        assertEq(IERC20(USDC).balanceOf(sender1), 0);

        console.log(
            "Celer-Bridge-Router gas cost for USDC-bridge to Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
