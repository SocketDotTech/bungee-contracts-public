import { ethers } from 'ethers';
import { addERC20Allowance } from '../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { flushERC20 } from '../../../../helper/flush-erc20';
import { getERC20Balance } from '../../../../helper/get-erc20-balance';
import * as CBridgeABI from "../../../../../abi/bridges/cbridge/CBridge.json";

export const simulateDirectBridgeERC20OnCBridge = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.CBRIDGE;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 100000000;
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const nonce = block_timestamp;
        const maxSlippage = 5000;

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('1'));

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await flushERC20(provider, token, sender);
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);

        const CELER_BRIDGE = '0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820';
        await addERC20Allowance(provider, token, sender, CELER_BRIDGE, bridgingAmount);

        const cBridgeInstance = new ethers.Contract(CELER_BRIDGE, CBridgeABI.abi, senderSigner);
        const bridgeTxn = await cBridgeInstance.send(recipient, token, bridgingAmount, destinationChainId, nonce, maxSlippage,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("CBridge ERC20-Bridge simulation failed");
        }

        gasUsed = txnReceipt.gasUsed.toString();

        const erc20BalanceAfterBridging = await getERC20Balance(provider, token, sender);

        if (parseInt(erc20BalanceAfterBridging) != 0) {
            throw new Error("CBridge ERC20-Bridge simulation failed - Assertion on ERC20 Balance after Bridging");
        }

        if (!txnReceipt.status) {
            throw new Error("Celer ERC20-Bridge simulation failed");
        }
    } catch (e) {
        console.error(`${e}`);
        isSuccessful = false;
        errorMessage = (e as Error).message;
    }

    return <SimulationResponse>({
        bridgeName: BridgeCodes[bridgeName],
        bridgeType: BridgeType[bridgeType],
        tokenType: TokenType[tokenType],
        tokenCode: TokenCodes[tokenCode],
        gasUsed: gasUsed,
        isSuccessful: isSuccessful,
        errorMessage: errorMessage,
        sourceChainCode: ChainCodes[sourceChain],
        sourceChainId: sourceChainId,
        destinationChainCode: ChainCodes[destinationChain],
        destinationChainId: destinationChainId,
        tokenAddress: token
    });
}
