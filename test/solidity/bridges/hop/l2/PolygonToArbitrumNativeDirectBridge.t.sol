// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {HopAMM} from "../../../../../src/bridges/hop/interfaces/amm.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";

contract HopPolygonToArbitrumNativeDirectBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    //Polygon Mainnet
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant recipient = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 37663689);
        vm.selectFork(fork);
    }

    function testDirectBridgeNative() public {
        address _hopAMM = 0x884d1Aa15F9957E1aEAA86a82a72e49Bc2bfCbe3;
        // fees passed to relayer
        uint256 _bonderFee = 20e16;
        uint256 _amountOutMin = 15e18;
        uint256 _deadline = block.timestamp + 100000;
        uint256 _amountOutMinDestination = 15e18;
        uint256 _deadlineDestination = block.timestamp + 100000;

        uint256 amount = 20e18;
        uint256 toChainId = 42161;

        deal(caller, amount);
        assertEq(caller.balance, amount);
        assertEq(recipient.balance, 0);

        vm.startPrank(caller);

        uint256 gasStockBeforeBridge = gasleft();

        // perform bridging
        HopAMM(_hopAMM).swapAndSend{value: amount}(
            toChainId,
            recipient,
            amount,
            _bonderFee,
            _amountOutMin,
            _deadline,
            _amountOutMinDestination,
            _deadlineDestination
        );

        uint256 gasStockAfterBridge = gasleft();

        assertEq(caller.balance, 0);
        assertEq(recipient.balance, 0);

        console.log(
            "HopL2-Direct-Bridge NativeToken from Ethereum to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
