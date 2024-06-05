import { ethers, BigNumber } from 'ethers';
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { flushNativeBalance } from '../../../../helper/flush-native-balance';
import * as CBridgeABI from "../../../../../abi/bridges/cbridge/CBridge.json";
import getRevertReason from 'eth-revert-reason';

export const simulateDirectBridgeNativeOnCBridge = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes , destinationChain: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.CBRIDGE;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = ethers.utils.parseEther('1');
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const nonce = block_timestamp;
        const maxSlippage = 10000;

        const senderSigner = provider.getSigner(sender);
        await flushNativeBalance(provider, sender);

        const gasReserve = ethers.utils.parseEther('0.1');
        await addNativeBalance(provider, sender, bridgingAmount.add(gasReserve));

        const CELER_BRIDGE = '0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820';
        const cBridgeInstance = new ethers.Contract(CELER_BRIDGE, CBridgeABI.abi, senderSigner);

        const bridgeTxn = await cBridgeInstance.sendNative(
            recipient, 
            bridgingAmount,
            BigNumber.from(destinationChainId), 
            BigNumber.from(nonce),
            BigNumber.from(maxSlippage),
            {
                value: bridgingAmount,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });
    

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            const revertReason = await getRevertReason(bridgeTxnHash);
            console.log(`ReverReason is: ${revertReason}`);
            throw new Error("CBridge Native-Direct-Bridge simulation failed");
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
        sourceChainCode: ChainCodes[sourceChain],
        sourceChainId: sourceChainId,
        destinationChainCode: ChainCodes[destinationChain],
        destinationChainId: destinationChainId,
        tokenAddress: token
      });
}
