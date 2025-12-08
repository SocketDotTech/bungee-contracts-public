// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import "../../utils/Ownable.sol";

interface IWETH {
    function withdraw(uint256 amount) external;
}

/**
 * @title AcrossV3WethUnwrapper
 * @notice Middleware contract to unwrap WETH received from Across V3 and forward ETH to recipient
 * @dev Implements handleV3AcrossMessage() to receive WETH from Across relayer
 *      The actual recipient address is encoded in the message parameter
 */
contract AcrossV3WethUnwrapper is Ownable {
    using SafeTransferLib for ERC20;

    /// @notice WETH token address on this chain
    address public immutable WETH;

    /// @notice SpokePool contract address
    address public immutable spokePool;

    /// @notice Emitted when WETH is unwrapped and ETH is forwarded
    event UnwrappedAndForwarded(
        address indexed recipient,
        uint256 amount,
        address indexed tokenSent
    );

    /// @notice Emitted when funds are rescued
    event FundsRescued(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @param _weth WETH token address
     * @param _owner Owner address for rescue functions
     * @param _spokePool SpokePool contract address
     */
    constructor(
        address _weth,
        address _owner,
        address _spokePool
    ) Ownable(_owner) {
        WETH = _weth;
        spokePool = _spokePool;
    }

    /**
     * @notice Handles WETH received from Across V3 relayer
     * @dev This function is called by Across relayer when filling a deposit
     *      The WETH has already been transferred to this contract before this function is called
     * @param tokenSent The token address sent (should be WETH)
     * @param amount The amount of WETH received
     * @param relayer The Across relayer address
     * @param message Encoded recipient address (abi.encode(address))
     */
    function handleV3AcrossMessage(
        address tokenSent,
        uint256 amount,
        address relayer,
        bytes memory message
    ) external {
        // Verify that the token sent is WETH
        require(tokenSent == WETH, "Only WETH supported");

        // Verify that the caller is the SpokePool
        require(
            msg.sender == spokePool,
            "Only SpokePool can call this function"
        );

        // Decode the actual recipient address from message
        address recipient = abi.decode(message, (address));
        require(recipient != address(0), "Invalid recipient");

        // Verify that this contract has received the WETH
        // The relayer has already transferred WETH to this contract before calling this function
        require(
            ERC20(WETH).balanceOf(address(this)) >= amount,
            "Insufficient WETH balance"
        );

        // Unwrap WETH to ETH
        IWETH(WETH).withdraw(amount);

        // Forward ETH to the actual recipient
        SafeTransferLib.safeTransferETH(recipient, amount);

        emit UnwrappedAndForwarded(recipient, amount, tokenSent);
    }

    /**
     * @notice Rescue ERC20 tokens stuck in the contract
     * @dev Only callable by owner
     * @param token Token address to rescue (use address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to rescue
     */
    function rescueFunds(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient");

        if (token == address(0)) {
            // Rescue native ETH
            SafeTransferLib.safeTransferETH(to, amount);
        } else {
            // Rescue ERC20 tokens
            ERC20(token).safeTransfer(to, amount);
        }

        emit FundsRescued(token, to, amount);
    }

    /**
     * @notice Rescue all of a specific ERC20 token
     * @dev Only callable by owner
     * @param token Token address to rescue
     * @param to Recipient address
     */
    function rescueFunds(address token, address to) external onlyOwner {
        require(to != address(0), "Invalid recipient");

        uint256 amount = ERC20(token).balanceOf(address(this));
        if (amount > 0) {
            ERC20(token).safeTransfer(to, amount);
            emit FundsRescued(token, to, amount);
        }
    }

    /**
     * @notice Rescue all native ETH
     * @dev Only callable by owner
     * @param to Recipient address
     */
    function rescueEther(address to) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        uint256 amount = address(this).balance;
        if (amount > 0) {
            SafeTransferLib.safeTransferETH(to, amount);
            emit FundsRescued(address(0), to, amount);
        }
    }

    /**
     * @notice Receive ETH (in case of direct sends)
     */
    receive() external payable {}
}
