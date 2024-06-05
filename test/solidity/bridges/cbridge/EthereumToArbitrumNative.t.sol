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

contract CelerEthereumToArbitrumNativeTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    //Polygon Mainnet
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

    function testBridgeNative() public {
        uint256 amount = 1e18;
        uint256 toChainId = 42161;
        uint64 nonce = uint64(block.timestamp);
        uint32 maxSlippage = 5000;
        bytes memory eventData = abi.encodePacked(
            "cbridge",
            "EthToArbitrumNative"
        );

        //sequence of arguments for implData: _receiverAddress, _token, _amount, _toChainId, nonce, maxSlippage
        bytes memory impldata = abi.encodeWithSelector(
            celerImpl.CELER_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            amount,
            metadata,
            uint64(toChainId),
            nonce,
            maxSlippage
        );

        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(socketGateway),
                receiver,
                WETH_ADDRESS,
                amount,
                uint64(toChainId),
                nonce,
                uint64(block.chainid)
            )
        );

        deal(sender1, amount);

        assertEq(sender1.balance, amount);
        assertEq(address(socketGateway).balance, 0);

        vm.startPrank(sender1);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute{value: amount}(513, impldata);

        uint256 gasStockAfterBridge = gasleft();

        address storedAddress = celerStorageWrapper.getAddressFromTransferId(
            transferId
        );
        assertEq(storedAddress, sender1);

        assertEq(sender1.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "Celer_Bridge-Router - gas cost for Native-bridge to Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }

    // function testForDuplicateTransferId() public {
    //     uint256 amount = 1e18;
    //     uint256 toChainId = 42161;
    //     uint64 nonce = uint64(block.timestamp);
    //     uint32 maxSlippage = 30000;
    //     bytes memory eventData = abi.encodePacked(
    //         "cbridge",
    //         "EthToArbitrumNative"
    //     );

    //     //sequence of arguments for implData: _receiverAddress, _token, _amount, _toChainId, nonce, maxSlippage
    //     bytes memory impldata = abi.encodeWithSelector(
    //         celerImpl.CELER_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
    //         receiver,
    //         amount,
    //         uint64(toChainId),
    //         nonce,
    //         maxSlippage
    //     );

    //     deal(sender1, amount);

    //     vm.startPrank(sender1);

    //     socketGateway.executeRoute{value: amount}(0, impldata, eventData);

    //     deal(sender1, amount);

    //     vm.expectRevert(TransferIdExists.selector);

    //     socketGateway.executeRoute{value: amount}(0, impldata, eventData);

    //     vm.stopPrank();
    // }
}
