// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {BridgeImplBase} from "../BridgeImplBase.sol";
import {IGnosisBridgeRouter} from "./interfaces/IGnosisBridgeRouter.sol";
import {GNOSIS_BRIDGE_ROUTER} from "../../static/RouteIdentifiers.sol";

/**
 * @title Gnosis Bridge Router Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native tokens via Gnosis Bridge Router
 * Called via SocketGateway if the routeId in the request maps to the routeId of GnosisBridgeRouterImpl
 * Contains function to handle bridging as post-step i.e linked to a preceding step for swap
 * @author Socket dot tech.
 */
contract GnosisBridgeRouterImpl is BridgeImplBase {
    using SafeTransferLib for ERC20;

    bytes32 public immutable GnosisBridgeRouterIdentifier =
        GNOSIS_BRIDGE_ROUTER;

    /// @notice max value for uint256
    uint256 public constant UINT256_MAX = type(uint256).max;

    /// @notice Function-selector for ERC20-token bridging on Gnosis-Bridge-Router
    /// @dev This function selector is to be used while building transaction-data to bridge ERC20 tokens
    bytes4
        public immutable GNOSIS_BRIDGE_ROUTER_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        GnosisBridgeRouterImpl.bridgeERC20To.selector;

    /// @notice Function-selector for Native bridging on Gnosis-Bridge-Router
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4
        public immutable GNOSIS_BRIDGE_ROUTER_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        GnosisBridgeRouterImpl.bridgeNativeTo.selector;

    /// @notice Function-selector for ERC20-token bridging on Gnosis-Bridge-Router
    /// @dev This function selector is to be used while building transaction-data to bridge ERC20 tokens
    bytes4 public immutable GNOSIS_BRIDGE_ROUTER_SWAP_BRIDGE_SELECTOR =
        GnosisBridgeRouterImpl.swapAndBridge.selector;

    struct GnosisBridgeRouterData {
        bytes32 metadata;
        address receiverAddress;
        address fromTokenAddress;
        uint256 toChainId;
        uint256 amount;
    }

    /// @notice The contract address of the Gnosis BridgeRouter on the source chain
    IGnosisBridgeRouter private immutable gnosisBridgeRouter;

    constructor(
        address _gnosisBridgeRouter,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        gnosisBridgeRouter = IGnosisBridgeRouter(_gnosisBridgeRouter);
    }

    /**
     * @notice function to handle ERC20 bridging to recipient via Gnosis BridgeRouter
     * @notice This method is payable because the caller is doing token transfer and bridging operation
     * @param metadata  socket offchain created hash
     * @param receiverAddress address of the receiver on the destination chain.
     * @param fromTokenAddress address of token being bridged
     * @param toChainId chainId of destination
     * @param amount amount to be bridged
     */
    function bridgeERC20To(
        bytes32 metadata,
        address receiverAddress,
        address fromTokenAddress,
        uint256 toChainId,
        uint256 amount
    ) external payable {
        ERC20(fromTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // approve Gnosis BridgeRouter if required
        if (
            amount >
            ERC20(fromTokenAddress).allowance(
                address(this),
                address(gnosisBridgeRouter)
            )
        ) {
            ERC20(fromTokenAddress).safeApprove(
                address(gnosisBridgeRouter),
                UINT256_MAX
            );
        }

        // if fromToken is DAI, USDS or any ERC20 token use BridgeRouter directly
        /// @dev BridgeRouter will handle each ERC20 token accordingly
        gnosisBridgeRouter.relayTokens(
            fromTokenAddress,
            receiverAddress,
            amount
        );

        emit SocketBridge(
            amount,
            fromTokenAddress,
            toChainId,
            GnosisBridgeRouterIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to recipient via Gnosis BridgeRouter
     * @notice This method is payable because the caller is doing token transfer and bridging operation
     * @param metadata  socket offchain created hash
     * @param receiverAddress address of the receiver on the destination chain.
     * @param toChainId chainId of destination
     * @param amount amount to be bridged
     */
    function bridgeNativeTo(
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId,
        uint256 amount
    ) external payable {
        /// @dev BridgeRouter will handle the Native token accordingly
        /// @dev BridgeRouter uses zero address as native token
        gnosisBridgeRouter.relayTokens{value: amount}(
            address(0),
            receiverAddress,
            amount
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            GnosisBridgeRouterIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this is called when the swap has already happened before this is called.
     * @notice This method is payable because the caller is doing token transfer and bridging operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in GnosisBridgeRouterData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Gnosis BridgeRouter
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        GnosisBridgeRouterData memory bridgeInfo = abi.decode(
            bridgeData,
            (GnosisBridgeRouterData)
        );

        // if fromToken is native ETH, use BridgeRouter directly
        if (bridgeInfo.fromTokenAddress == NATIVE_TOKEN_ADDRESS) {
            /// @dev BridgeRouter will handle the Native token accordingly
            /// @dev BridgeRouter uses zero address as native token
            gnosisBridgeRouter.relayTokens{value: amount}(
                address(0),
                bridgeInfo.receiverAddress,
                amount
            );

            emit SocketBridge(
                amount,
                NATIVE_TOKEN_ADDRESS,
                bridgeInfo.toChainId,
                GnosisBridgeRouterIdentifier,
                msg.sender,
                bridgeInfo.receiverAddress,
                bridgeInfo.metadata
            );
        }
        // if fromToken is DAI, USDS or any ERC20 token use BridgeRouter directly
        else {
            // approve Gnosis BridgeRouter if required
            if (
                amount >
                ERC20(bridgeInfo.fromTokenAddress).allowance(
                    address(this),
                    address(gnosisBridgeRouter)
                )
            ) {
                ERC20(bridgeInfo.fromTokenAddress).safeApprove(
                    address(gnosisBridgeRouter),
                    UINT256_MAX
                );
            }

            /// @dev BridgeRouter will handle each ERC20 token accordingly
            gnosisBridgeRouter.relayTokens(
                bridgeInfo.fromTokenAddress,
                bridgeInfo.receiverAddress,
                amount
            );

            emit SocketBridge(
                amount,
                bridgeInfo.fromTokenAddress,
                bridgeInfo.toChainId,
                GnosisBridgeRouterIdentifier,
                msg.sender,
                bridgeInfo.receiverAddress,
                bridgeInfo.metadata
            );
        }
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and bridging operation
     * @dev for usage, refer to controller implementations
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param metadata  socket offchain created hash
     * @param receiverAddress   address of the token to bridged to the destination chain.
     * @param toChainId chainId of destination
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        // if fromToken is native ETH, use BridgeRouter directly
        if (token == NATIVE_TOKEN_ADDRESS) {
            /// @dev BridgeRouter will handle the Native token accordingly
            /// @dev BridgeRouter uses zero address as native token
            gnosisBridgeRouter.relayTokens{value: bridgeAmount}(
                address(0),
                receiverAddress,
                bridgeAmount
            );

            emit SocketBridge(
                bridgeAmount,
                NATIVE_TOKEN_ADDRESS,
                toChainId,
                GnosisBridgeRouterIdentifier,
                msg.sender,
                receiverAddress,
                metadata
            );
        }
        // if fromToken is DAI, USDS or any ERC20 token use BridgeRouter directly
        else {
            // approve Gnosis BridgeRouter if required
            if (
                bridgeAmount >
                ERC20(token).allowance(
                    address(this),
                    address(gnosisBridgeRouter)
                )
            ) {
                ERC20(token).safeApprove(
                    address(gnosisBridgeRouter),
                    UINT256_MAX
                );
            }

            /// @dev BridgeRouter will handle each ERC20 token accordingly
            gnosisBridgeRouter.relayTokens(
                token,
                receiverAddress,
                bridgeAmount
            );

            emit SocketBridge(
                bridgeAmount,
                token,
                toChainId,
                GnosisBridgeRouterIdentifier,
                msg.sender,
                receiverAddress,
                metadata
            );
        }
    }
}
