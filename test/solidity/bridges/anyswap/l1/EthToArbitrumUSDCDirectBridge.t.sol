// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../../lib/forge-std/src/Vm.sol";
import "../../../../../lib/forge-std/src/console.sol";
import "../../../../../lib/forge-std/src/Script.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SocketGatewayBaseTest} from "../../../SocketGatewayBaseTest.sol";

/**
 * @title Anyswap L1 Implementation.
 * @notice This is the L1 implementation, so this is used when transferring from
 * l1 to supported l1s or L1.
 * Called by the registry if the selected bridge is Anyswap bridge.
 * @dev Follows the interface of ImplBase.
 * @author Movr Network.
 */
interface AnyswapV3Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapEthToArbitrumUSDCDirectBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    using SafeERC20 for IERC20;

    //ETH Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ANY_SWAP_USDC = 0x7EA2be2df7BA6E54B1A9C70676f668455E329d29;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant routerAddress = 0x6b7a87899490EcE95443e979cA9485CBE7E71522;
    AnyswapV3Router public router;

    function setUp() public {
        //https://etherscan.io/tx/0xc783cf4a60e68ba453f8786a96e0a233de8a4dcbb15bcf4c7c4a0f7738fbb8f1
        uint256 fork = vm.createFork(vm.envString("ETHEREUM_RPC"), 15588208);
        vm.selectFork(fork);
        router = AnyswapV3Router(routerAddress);
    }

    function testBridgeUSDC() public {
        uint256 amount = 100e6;
        uint256 toChainId = 42161;

        vm.startPrank(sender1);
        deal(address(USDC), address(sender1), amount);
        assertEq(IERC20(USDC).balanceOf(sender1), amount);
        IERC20(USDC).approve(caller, amount);
        vm.stopPrank();

        vm.startPrank(caller);

        IERC20(USDC).safeTransferFrom(sender1, caller, amount);
        IERC20(USDC).safeIncreaseAllowance(routerAddress, amount);

        uint256 gasStockBeforeBridge = gasleft();

        router.anySwapOutUnderlying(ANY_SWAP_USDC, receiver, amount, toChainId);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(sender1.balance, 0);
        assertEq(caller.balance, 0);
        assertEq(receiver.balance, 0);

        console.log(
            "AnyswapL1-Direct-Bridge USDC from Ethereum to Arbitrum costed: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
