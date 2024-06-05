// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import "../../../lib/forge-std/src/console.sol";
import "../../../lib/forge-std/src/Script.sol";
import "../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest, SocketGateway, SocketDeployFactory, DisabledSocketRoute} from "../SocketGatewayBaseTest.sol";
import {HopImplL1} from "../../../src/bridges/hop/l1/HopImplL1.sol";
// import {HopImplL2} from "../../../src/bridges/hop/l2/HopImplL2.sol";
import {StargateImplL1} from "../../../src/bridges/stargate/l1/Stargate.sol";
import {CelerImpl} from "../../../src/bridges/cbridge/CelerImpl.sol";
import {CelerStorageWrapper} from "../../../src/bridges/cbridge/CelerStorageWrapper.sol";
import {ISocketRoute} from "../../../src/interfaces/ISocketRoute.sol";
import {Address0Provided, OnlyOwner, OnlySocketDeployer} from "../../../src/errors/SocketErrors.sol";

contract SocketDeployTest is Test, SocketGatewayBaseTest {
    SocketGateway internal socketGateway;
    DisabledSocketRoute internal disabledRoute;
    SocketDeployFactory internal socketDeployFactory;

    error ContractAlreadyDeployed();
    error NothingToDestroy();
    error AlreadyDisabled();
    error CannotBeDisabled();
    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant router = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    address constant routerETH = 0x150f94B44927F078737562f0fcF3C95c01Cc2376;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant celerReceiver = 0x2FA81527389929Ae9FD0f9ACa9e16Cba37D3EeA1;
    address constant CELER_BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    address constant WETH_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address predicted1;
    address predicted2;

    address socket1;
    address socket2;
    address socket3;
    HopImplL1 internal hopImpl;
    StargateImplL1 internal stargateImpl;
    CelerImpl internal celerImpl;
    CelerStorageWrapper internal celerStorageWrapper;

    event NewRouteAdded(uint32 indexed routeId, address indexed route);
    event RouteDisabled(uint32 indexed routeID);

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15819486);
        vm.selectFork(fork);
        vm.startPrank(owner);
        socketGateway = createSocketGateway();
        disabledRoute = createDisabledSocketRouteContract(
            address(socketGateway)
        );
        socketDeployFactory = createSocketDeployFactory(address(disabledRoute));
        predicted1 = socketDeployFactory.getContractAddress(1);
        predicted2 = socketDeployFactory.getContractAddress(2);
        hopImpl = new HopImplL1(
            address(socketGateway),
            address(socketDeployFactory)
        );
        stargateImpl = new StargateImplL1(
            router,
            routerETH,
            address(socketGateway),
            address(socketDeployFactory)
        );

        celerStorageWrapper = new CelerStorageWrapper(address(socketGateway));
        celerImpl = new CelerImpl(
            CELER_BRIDGE,
            WETH_ADDRESS,
            address(celerStorageWrapper),
            address(socketGateway),
            address(socketDeployFactory)
        );

        socket1 = socketDeployFactory.deploy(1, address(hopImpl));
        socket2 = socketDeployFactory.deploy(2, address(stargateImpl));
        socket3 = socketDeployFactory.deploy(3, address(celerImpl));

        console.log("predicted address 1: ", predicted1);
        console.log("predicted address 2: ", predicted2);
        console.log("deployed socket address 1: ", socket1);
        console.log("deployed socket address 2: ", socket2);
        console.log("deployed socket address 3: ", socket3);

        uint32 routeId = 497;
        // bytes4 x = bytes4(routeId);

        console.log("address at position", socketGateway.addressAt(routeId));
        vm.stopPrank();
        // console.logBytes(socketGateway.codeAt(x));
    }

    function testRevertOnRedeployOnSameSalt() public {
        vm.startPrank(owner);
        vm.expectRevert(ContractAlreadyDeployed.selector);
        socketDeployFactory.deploy(1, address(stargateImpl));
        vm.stopPrank();
    }

    function testRevertOnDestroyingUnconfiguredSalt() public {
        vm.startPrank(owner);
        vm.expectRevert(NothingToDestroy.selector);
        socketDeployFactory.destroy(4);
        vm.stopPrank();
    }

    function testDestroy() public {
        vm.startPrank(owner);
        socketDeployFactory.destroy(1);
        vm.stopPrank();
    }

    function testDestroyRevertNonDeployer() public {
        vm.startPrank(owner);
        vm.expectRevert(OnlySocketDeployer.selector);
        hopImpl.killme();
        vm.stopPrank();
    }

    function testDeployWasteRevert() public {
        vm.startPrank(owner);
        vm.expectRevert(CannotBeDisabled.selector);
        socketDeployFactory.disableRoute(7);
        vm.stopPrank();
    }

    function testBridgeUSDCHopImplL1() public {
        vm.startPrank(sender1);

        address _l1bridgeAddr = 0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
        address _relayer = 0x0000000000000000000000000000000000000000;
        uint256 _amountOutMin = 90e6;
        uint256 _relayerFee = 0;
        uint256 _deadline = block.timestamp + 100000;

        uint256 amount = 100e6;
        address token = USDC;

        // bytes memory eventData = abi.encodePacked(
        //     "hop-L1",
        //     "EthToArbitrumUSDC"
        // );

        bytes memory impldata = abi.encodeWithSelector(
            hopImpl.HOP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            sender1,
            token,
            _l1bridgeAddr,
            _relayer,
            42161,
            amount,
            _amountOutMin,
            _relayerFee,
            _deadline
        );

        deal(address(token), address(sender1), amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);
        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);

        IERC20(token).approve(address(socketGateway), amount);

        uint32 position = 497;
        bytes4 positionInHex = bytes4(position);
        bytes memory mergedData = bytes.concat(positionInHex, impldata);

        uint256 gasStockBeforeBridge = gasleft();
        (bool success, ) = address(socketGateway).call(mergedData);
        uint256 gasStockAfterBridge = gasleft();

        assertEq(success, true);
        console.log(
            "LL-Hop-Route on Eth-Mainnet gas-cost for USDC-bridge: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        assertEq(IERC20(token).balanceOf(address(socketGateway)), 0);
        assertEq(IERC20(token).balanceOf(sender1), 0);

        vm.stopPrank();
    }

    function testBridgeNative() public {
        uint256 minReceivedAmt = 1e16;
        uint256 optionalValue = 1e16;
        uint256 stargateDstChainId = 111;
        address senderAddress = sender1;
        uint256 amount = 1e18;
        // bytes memory eventData = abi.encodePacked("stargate-l1", "NATIVE");

        // receiverAddress, token, senderAddress, amount, value, srcPoolId, dstPoolId, minReceivedAmt, optionalValue, destinationGasLimit, stargateDstChainId, destinationPayload
        bytes memory impldata = abi.encodeWithSelector(
            stargateImpl.STARGATE_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            receiver,
            senderAddress,
            uint16(stargateDstChainId),
            amount,
            minReceivedAmt,
            optionalValue
        );

        uint32 position = 498;
        bytes4 positionInHex = bytes4(position);
        bytes memory mergedData = bytes.concat(positionInHex, impldata);

        vm.startPrank(sender1);
        deal(sender1, amount + optionalValue);
        console.log("sender1.balance", sender1.balance);
        console.log(
            "address(socketGateway).balance",
            address(socketGateway).balance,
            address(socketGateway)
        );
        console.log("receiver.balance", receiver.balance);
        assertEq(sender1.balance, amount + optionalValue);
        assertEq(receiver.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        uint256 gasStockBeforeBridge = gasleft();
        (bool success, ) = address(socketGateway).call{
            value: amount + optionalValue
        }(mergedData);
        // socketGateway.executeRoute{value: amount + optionalValue}(
        //     513,
        //     impldata,
        //     eventData
        // );

        uint256 gasStockAfterBridge = gasleft();
        assertEq(success, true);
        assertEq(receiver.balance, 0);
        assertEq(address(socketGateway).balance, 0);

        console.log(
            "Stargate-L1-Router gas-cost for Native Bridging to Optimism: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }

    function testBridgeNativeCeler() public {
        uint256 amount = 1e18;
        uint256 toChainId = 42161;
        uint64 nonce = uint64(block.timestamp);
        uint32 maxSlippage = 5000;
        // bytes memory eventData = abi.encodePacked(
        //     "cbridge",
        //     "EthToArbitrumNative"
        // );

        //sequence of arguments for implData: _receiverAddress, _token, _amount, _toChainId, nonce, maxSlippage
        bytes memory impldata = abi.encodeWithSelector(
            celerImpl.CELER_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR(),
            celerReceiver,
            amount,
            uint64(toChainId),
            nonce,
            maxSlippage
        );

        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(socketGateway),
                celerReceiver,
                WETH_ADDRESS,
                amount,
                uint64(toChainId),
                nonce,
                uint64(block.chainid)
            )
        );
        uint32 position = 499;
        bytes4 positionInHex = bytes4(position);
        bytes memory mergedData = bytes.concat(positionInHex, impldata);
        deal(sender1, amount);

        assertEq(sender1.balance, amount);
        assertEq(address(socketGateway).balance, 0);

        vm.startPrank(sender1);

        uint256 gasStockBeforeBridge = gasleft();

        (bool success, ) = address(socketGateway).call{value: amount}(
            mergedData
        );

        assertEq(success, true);
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
}
