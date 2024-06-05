// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {GnosisNativeBridgeImpl} from "../../../../src/bridges/gnosis-native/gnosisNativeImpl.sol";
import {ISocketRoute} from "../../../../src/interfaces/ISocketRoute.sol";

contract GnosisNativeDaiToXdaiTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    bytes32 metadata =
        0x28fd8a5dda29b4035905e0657f97244a0e0bef97951e248ed0f2c6878d6590c2;
    address constant _gnosisXdaiBridge =
        0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016;
    address constant _gnosisOmniBridge =
        0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016;
    address constant _gnosisWethOmniBridgeHelper =
        0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant DAI_ON_ETH = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant XDAI = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 amount = 0xDE0B6B3A7640000;
    address constant receiver = 0x17Ac6982b9CeAfbB36ee486722E8EB0f30b1E97D;

    GnosisNativeBridgeImpl internal gnosisImpl;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 18611715);
        vm.selectFork(fork);
        socketGateway = createSocketGateway();
        gnosisImpl = new GnosisNativeBridgeImpl(
            _gnosisXdaiBridge,
            _gnosisOmniBridge,
            _gnosisWethOmniBridgeHelper,
            address(socketGateway),
            address(socketGateway)
        );
        address route_0 = address(gnosisImpl);

        // Emits Event
        emit NewRouteAdded(0, address(gnosisImpl));
        vm.startPrank(owner);
        socketGateway.addRoute(route_0);
        vm.stopPrank();
    }

    function testSendDaiToXDaiBridging() public {
        bytes memory impldata = abi.encodeWithSelector(
            gnosisImpl
                .GNOSIS_NATIVE_BRIDGE_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            metadata,
            sender1,
            DAI_ON_ETH,
            XDAI,
            100,
            amount
        );

        deal(address(DAI_ON_ETH), address(sender1), amount);
        assertEq(IERC20(DAI_ON_ETH).balanceOf(sender1), amount);
        assertEq(IERC20(DAI_ON_ETH).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(DAI_ON_ETH).balanceOf(receiver), 0);

        vm.startPrank(sender1);
        IERC20(DAI_ON_ETH).approve(address(socketGateway), amount);

        uint256 gasStockBeforeBridge = gasleft();

        socketGateway.executeRoute(385, impldata);

        uint256 gasStockAfterBridge = gasleft();

        console.log(
            "gnosis-Bridge-Router DAI from Ethereum to gnosis xDai costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
