// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGnosisBridgeRouter {
    /**
     * @notice An entry point contract for user to bridge any token from source chain
     * @dev DAI: Directly bridge via xDaiBridge
     *      USDS: Swaps USDS to DAI and then bridge via xDaiBridge
     *      Native: Wraps native ETH to WETH and bridge via OmniBridge
     *      Other ERC20 tokens: Bridge via OmniBridge
     * @param _token token to bridge
     * @param _receiver receiver of token on Gnosis Chain
     * @param _amount amount to receive on Gnosis Chain
     */
    function relayTokens(
        address _token,
        address _receiver,
        uint256 _amount
    ) external payable;
}
