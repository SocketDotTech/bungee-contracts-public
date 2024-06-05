import { BigNumber, ethers } from 'ethers';
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import * as SpokePoolABI from "../../../../../abi/bridges/across/SpokePool.json";
import { getNativeBalance } from '../../../../helper/get-native-balance';

export const simulateDirectBridgeNativeOnAcross = async (provider: any, forkBlockNumber: number, sourceChainCode: ChainCodes, destinationChainCode: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChainCode) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChainCode) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.ACROSS;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChainCode) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const _relayerFeePct = ethers.BigNumber.from(0);
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const _quoteTimestamp = block_timestamp;
        const bridgingAmount = ethers.utils.parseEther('1');
        const gasReserve =  ethers.utils.parseEther('0.2');
        const senderSigner = provider.getSigner(sender);

        const spokePoolAddress = '0x4D9079Bb4165aeb4084c526a32695dCfd2F77381';
        const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
        const spokePoolBridgeInstance = new ethers.Contract(spokePoolAddress, SpokePoolABI.abi, senderSigner);
        
        await addNativeBalance(provider, sender, bridgingAmount.add(gasReserve));
        const bridgeTxn = await spokePoolBridgeInstance.deposit(recipient, WETH,
            bridgingAmount, destinationChainId, _relayerFeePct, _quoteTimestamp,
            {   
                value: bridgingAmount,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("Across Native-Direct-Bridge simulation failed");
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
