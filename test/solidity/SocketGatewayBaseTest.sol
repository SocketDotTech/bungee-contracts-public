// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../src/SocketGatewayDeployment.sol";
import "../../src/deployFactory/SocketDeployFactory.sol";
import "../../src/deployFactory/DisabledSocketRoute.sol";
import "forge-std/console.sol";

contract SocketGatewayBaseTest {
    address constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address internal constant ZERO_ADDRESS = address(0);
    address public immutable DISABLED_ROUTE =
        0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address constant owner = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    bytes constant EMPTY_DATA = "0x";

    bytes32 public immutable ACROSS = keccak256("Across");

    bytes32 public immutable ANYSWAP = keccak256("Anyswap");

    bytes32 public immutable CBRIDGE = keccak256("CBridge");

    bytes32 public immutable HOP = keccak256("Hop");

    bytes32 public immutable HYPHEN = keccak256("Hyphen");

    bytes32 public immutable NATIVE_OPTIMISM = keccak256("NativeOptimism");

    bytes32 public immutable NATIVE_ARBITRUM = keccak256("NativeArbitrum");

    bytes32 public immutable NATIVE_POLYGON = keccak256("NativePolygon");

    bytes32 public immutable REFUEL = keccak256("Refuel");

    bytes32 public immutable STARGATE = keccak256("Stargate");

    bytes32 public immutable ONEINCH = keccak256("OneInch");

    bytes32 public immutable ZEROX = keccak256("Zerox");

    bytes32 public immutable RAINBOW = keccak256("Rainbow");

    bytes public socketData =
        hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3";

    bytes4 public immutable optimisedBridgeErc20Selector =
        bytes4(keccak256("bridgeERC20ToOptimised()"));

    bytes4 public immutable optimisedBridgeNativeSelector =
        bytes4(keccak256("bridgeNativeToOptimised()"));

    event SocketSwapTokens(
        address fromToken,
        address toToken,
        uint256 buyAmount,
        uint256 sellAmount,
        bytes32 routeName,
        address receiver
    );

    event SocketBridge(
        uint256 amount,
        address token,
        uint256 toChainId,
        bytes32 bridgeName,
        address sender,
        address receiver
    );

    function createSocketGateway() internal returns (SocketGateway) {
        return new SocketGateway(owner, DISABLED_ROUTE);
    }

    function createDisabledSocketRouteContract(
        address s
    ) internal returns (DisabledSocketRoute) {
        return new DisabledSocketRoute(s);
    }

    function createSocketDeployFactory(
        address wasteContract
    ) internal returns (SocketDeployFactory) {
        return new SocketDeployFactory(owner, wasteContract);
    }
}
