import { ethers } from 'ethers';
import * as SpokePoolABI from "../../../../../abi/bridges/across/SpokePool.json";
import { addERC20Allowance } from '../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { flushERC20 } from '../../../../helper/flush-erc20';

export const simulateDirectBridgeERC20OnAcross = async (provider: any, forkBlockNumber: number, sourceChainCode: ChainCodes, destinationChainCode: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChainCode) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChainCode) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.ACROSS;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChainCode) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {

        const spokePoolAddress = '0x4D9079Bb4165aeb4084c526a32695dCfd2F77381';
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const _relayerFeePct = ethers.BigNumber.from(0);
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const _quoteTimestamp = ethers.BigNumber.from(block_timestamp);
        const bridgingAmount = 100000000;

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('0.1'));

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await flushERC20(provider, token, sender);
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, spokePoolAddress, bridgingAmount);

        const spokePoolBridgeInstance = new ethers.Contract(spokePoolAddress, SpokePoolABI.abi, senderSigner);
        const bridgeTxn = await spokePoolBridgeInstance.deposit(recipient, token,
            bridgingAmount, destinationChainId, _relayerFeePct, _quoteTimestamp,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("Across ERC20-Direct-Bridge simulation failed");
        }

        gasUsed = txnReceipt.gasUsed.toString();
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
        sourceChainCode: ChainCodes[sourceChainCode],
        sourceChainId: sourceChainId,
        destinationChainCode: ChainCodes[destinationChainCode],
        destinationChainId: destinationChainId,
        tokenAddress: token
    });
}
