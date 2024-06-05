import { ethers, BigNumber } from 'ethers';
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { flushNativeBalance } from '../../../../helper/flush-native-balance';
import * as HyphenLiquidityPoolManagerABI from '../../../../../abi/bridges/hyphen/HyphenLiquidityPoolManager.json';

export const simulateDirectBridgeNativeOnHyphen = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.HYPHEN;
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

        const liquidityPoolManagerAddress = '0x2A5c2568b10A0E826BfA892Cf21BA7218310180b';
        const tag = "SOCKET";

        const senderSigner = provider.getSigner(sender);

        const hyphenBridgeInstance = new ethers.Contract(liquidityPoolManagerAddress, HyphenLiquidityPoolManagerABI.abi, senderSigner);

        const bridgeTxn = await hyphenBridgeInstance.depositNative(
            recipient, destinationChainId, tag,
            {
                value: bridgingAmount,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        gasUsed = txnReceipt.gasUsed.toString();

        if (!txnReceipt.status) {
            throw new Error("HyphenL1 Native-Direct-Bridge simulation failed");
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
