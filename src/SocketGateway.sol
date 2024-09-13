// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {LibUtil} from "./libraries/LibUtil.sol";
import "./libraries/LibBytes.sol";
import {ISocketRoute} from "./interfaces/ISocketRoute.sol";
import {ISocketRequest} from "./interfaces/ISocketRequest.sol";
import {ISocketGateway} from "./interfaces/ISocketGateway.sol";
import {IncorrectBridgeRatios, ZeroAddressNotAllowed, ArrayLengthMismatch} from "./errors/SocketErrors.sol";

/// @title SocketGatewayContract
/// @notice Socketgateway is a contract with entrypoint functions for all interactions with socket liquidity layer
/// @author Socket Team
contract SocketGatewayTemplate is Ownable {
    using LibBytes for bytes;
    using LibBytes for bytes4;
    using SafeTransferLib for ERC20;

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice storage variable to keep track of total number of routes registered in socketgateway
    uint32 public routesCount = 385;

    /// @notice storage variable to keep track of total number of controllers registered in socketgateway
    uint32 public controllerCount;

    address public immutable disabledRouteAddress;

    uint256 public constant CENT_PERCENT = 100e18;

    /// @notice storage mapping for route implementation addresses
    mapping(uint32 => address) public routes;

    /// storage mapping for controller implemenation addresses
    mapping(uint32 => address) public controllers;
    
    // Events ------------------------------------------------------------------------------------------------------->

    /// @notice Event emitted when a router is added to socketgateway
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    /// @notice Event emitted when a route is disabled
    event RouteDisabled(uint32 indexed routeId);

    /// @notice Event emitted when ownership transfer is requested by socket-gateway-owner
    event OwnershipTransferRequested(
        address indexed _from,
        address indexed _to
    );

    /// @notice Event emitted when a controller is added to socketgateway
    event ControllerAdded(
        uint32 indexed controllerId,
        address indexed controllerAddress
    );

    /// @notice Event emitted when a controller is disabled
    event ControllerDisabled(uint32 indexed controllerId);

    constructor(address _owner, address _disabledRoute) Ownable(_owner) {
        disabledRouteAddress = _disabledRoute;
    }

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /*******************************************
     *          EXTERNAL AND PUBLIC FUNCTIONS  *
     *******************************************/

    /**
     * @notice executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in routeData to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeId route identifier
     * @param routeData functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoute(
        uint32 routeId,
        bytes calldata routeData
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = addressAt(routeId).delegatecall(
            routeData
        );

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice swaps a token on sourceChain and split it across multiple bridge-recipients
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being swapped
     * @dev ensure the swap-data and bridge-data is generated using the function-selector defined as a constant in the implementation address
     * @param swapMultiBridgeRequest request
     */
    function swapAndMultiBridge(
        ISocketRequest.SwapMultiBridgeRequest calldata swapMultiBridgeRequest
    ) external payable {
        uint256 requestLength = swapMultiBridgeRequest.bridgeRouteIds.length;

        if (
            requestLength != swapMultiBridgeRequest.bridgeImplDataItems.length
        ) {
            revert ArrayLengthMismatch();
        }
        uint256 ratioAggregate;
        for (uint256 index = 0; index < requestLength; ) {
            ratioAggregate += swapMultiBridgeRequest.bridgeRatios[index];
        }

        if (ratioAggregate != CENT_PERCENT) {
            revert IncorrectBridgeRatios();
        }

        (bool swapSuccess, bytes memory swapResult) = addressAt(
            swapMultiBridgeRequest.swapRouteId
        ).delegatecall(swapMultiBridgeRequest.swapImplData);

        if (!swapSuccess) {
            assembly {
                revert(add(swapResult, 32), mload(swapResult))
            }
        }

        uint256 amountReceivedFromSwap = abi.decode(swapResult, (uint256));

        uint256 bridgedAmount;

        for (uint256 index = 0; index < requestLength; ) {
            uint256 bridgingAmount;

            // if it is the last bridge request, bridge the remaining amount
            if (index == requestLength - 1) {
                bridgingAmount = amountReceivedFromSwap - bridgedAmount;
            } else {
                // bridging amount is the multiplication of bridgeRatio and amountReceivedFromSwap
                bridgingAmount =
                    (amountReceivedFromSwap *
                        swapMultiBridgeRequest.bridgeRatios[index]) /
                    (CENT_PERCENT);
            }

            // update the bridged amount, this would be used for computation for last bridgeRequest
            bridgedAmount += bridgingAmount;

            bytes memory bridgeImpldata = abi.encodeWithSelector(
                BRIDGE_AFTER_SWAP_SELECTOR,
                bridgingAmount,
                swapMultiBridgeRequest.bridgeImplDataItems[index]
            );

            (bool bridgeSuccess, bytes memory bridgeResult) = addressAt(
                swapMultiBridgeRequest.bridgeRouteIds[index]
            ).delegatecall(bridgeImpldata);

            if (!bridgeSuccess) {
                assembly {
                    revert(add(bridgeResult, 32), mload(bridgeResult))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice sequentially executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each dataItem to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeIds a list of route identifiers
     * @param dataItems a list of functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoutes(
        uint32[] calldata routeIds,
        bytes[] calldata dataItems
    ) external payable {
        uint256 routeIdslength = routeIds.length;
        if (routeIdslength != dataItems.length) revert ArrayLengthMismatch();
        for (uint256 index = 0; index < routeIdslength; ) {
            (bool success, bytes memory result) = addressAt(routeIds[index])
                .delegatecall(dataItems[index]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice execute a controller function identified using the controllerId in the request
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param socketControllerRequest socketControllerRequest with controllerId to identify the
     *                                   controllerAddress and byteData constructed using functionSelector
     *                                   of the function being invoked
     * @return bytes data received from the call delegated to controller
     */
    function executeController(
        ISocketGateway.SocketControllerRequest calldata socketControllerRequest
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = controllers[
            socketControllerRequest.controllerId
        ].delegatecall(socketControllerRequest.data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice sequentially executes all controller requests
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each controller-request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param controllerRequests a list of socketControllerRequest
     *                              Each controllerRequest contains controllerId to identify the controllerAddress and
     *                              byteData constructed using functionSelector of the function being invoked
     */
    function executeControllers(
        ISocketGateway.SocketControllerRequest[] calldata controllerRequests
    ) external payable {
        for (uint32 index = 0; index < controllerRequests.length; ) {
            (bool success, bytes memory result) = controllers[
                controllerRequests[index].controllerId
            ].delegatecall(controllerRequests[index].data);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(
        address routeAddress
    ) external onlyOwner returns (uint32) {
        uint32 routeId = routesCount;
        routes[routeId] = routeAddress;

        routesCount += 1;

        emit NewRouteAdded(routeId, routeAddress);

        return routeId;
    }

    /**
     * @notice Give Infinite or 0 approval to bridgeRoute for the tokenAddress
               This is a restricted function to be called by only socketGatewayOwner
     */

    function setApprovalForRouters(
        address[] memory routeAddresses,
        address[] memory tokenAddresses,
        bool isMax
    ) external onlyOwner {
        for (uint32 index = 0; index < routeAddresses.length; ) {
            ERC20(tokenAddresses[index]).approve(
                routeAddresses[index],
                isMax ? type(uint256).max : 0
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address controllerAddress
    ) external onlyOwner returns (uint32) {
        uint32 controllerId = controllerCount;

        controllers[controllerId] = controllerAddress;

        controllerCount += 1;

        emit ControllerAdded(controllerId, controllerAddress);

        return controllerId;
    }

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 controllerId) public onlyOwner {
        controllers[controllerId] = disabledRouteAddress;
        emit ControllerDisabled(controllerId);
    }

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external onlyOwner {
        routes[routeId] = disabledRouteAddress;
        emit RouteDisabled(routeId);
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTIONS    *
     *******************************************/

    /**
     * @notice Rescues the ERC20 token to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param token address of the ERC20 token being rescued
     * @param userAddress address to which ERC20 is to be rescued
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice Rescues the native balance to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param userAddress address to which native-balance is to be rescued
     * @param amount amount of native-balance being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) public view returns (address) {
        return addressAt(routeId);
    }

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 controllerId) public view returns (address) {
        return controllers[controllerId];
    }

    /// @notice Retrieves the address associated with a given route ID
    /// @dev This function uses a combination of a default address for IDs < 385
    ///      and a mapping lookup for IDs >= 385 to optimize gas costs
    /// @param routeId The ID of the route to look up
    /// @return The address associated with the given route ID
    function addressAt(uint32 routeId) public view returns (address) {
        // For route IDs less than 385, return a default address
        // This optimizes gas costs for frequently used routes
        if (routeId < 385) {
            return 0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
        }
        
        // For route IDs 385 and above, use the routes mapping
        address routeAddress = routes[routeId];
        
        // Revert if the route address is zero
        if (routeAddress == address(0)) revert ZeroAddressNotAllowed();
        
        return routeAddress;
    }

    /// @notice fallback function to handle swap, bridge execution
    /// @dev ensure routeId is converted to bytes4 and sent as msg.sig in the transaction
    fallback() external payable {
        address routeAddress = addressAt(uint32(msg.sig));

        bytes memory result;

        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 4, sub(calldatasize(), 4))
            // execute function call using the facet
            result := delegatecall(
                gas(),
                routeAddress,
                0,
                sub(calldatasize(), 4),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
