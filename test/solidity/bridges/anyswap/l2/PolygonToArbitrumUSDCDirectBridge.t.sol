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

contract AnyswapPolygonToArbitrumUSDCDirectBridgeTest is
    Test,
    SocketGatewayBaseTest
{
    using SafeERC20 for IERC20;

    //Polygon Mainnet
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant ANY_SWAP_USDC = 0xd69b31c3225728CC57ddaf9be532a4ee1620Be51;
    address constant caller = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;
    address constant sender1 = 0x246Add954192f59396785f7195b8CB36841a9bE8;
    address constant receiver = 0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba;
    address constant routerAddress = 0x4f3Aff3A747fCADe12598081e80c6605A8be192F;
    AnyswapV3Router public router;

    function setUp() public {
        //https://polygonscan.com/tx/0xdc031c883bfd1bca7f4bc56312fead0b6acfaf3130910e81e12134df29fbe1a5
        uint256 fork = vm.createFork(vm.envString("POLYGON_RPC"), 34236074);
        vm.selectFork(fork);
        router = AnyswapV3Router(routerAddress);
    }

    function testBridgeUSDC() public {
        uint256 amount = 100e6;
        uint256 toChainId = 42161;
        address token = USDC;

        deal(address(token), address(sender1), amount);
        assertEq(IERC20(token).balanceOf(sender1), amount);

        vm.startPrank(sender1);
        IERC20(token).approve(caller, amount);
        vm.stopPrank();

        assertEq(IERC20(token).balanceOf(caller), 0);

        vm.startPrank(caller);

        IERC20(token).safeTransferFrom(sender1, caller, amount);
        IERC20(token).safeIncreaseAllowance(routerAddress, amount);

        uint256 gasStockBeforeBridge = gasleft();

        router.anySwapOutUnderlying(ANY_SWAP_USDC, receiver, amount, toChainId);

        uint256 gasStockAfterBridge = gasleft();

        assertEq(IERC20(token).balanceOf(sender1), 0);
        assertEq(IERC20(token).balanceOf(caller), 0);

        console.log(
            "AnySwap-L2-Direct-Bridge GasCost from Polygon to Arbitrum: ",
            gasStockBeforeBridge - gasStockAfterBridge
        );

        vm.stopPrank();
    }
}
