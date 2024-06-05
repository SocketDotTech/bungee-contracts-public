import { ethers, BigNumber } from 'ethers';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { flushNativeBalance } from '../../../../../helper/flush-native-balance';
import * as IRouterEth from "../../../../../../abi/bridges/stargate/IRouterEth.json";

export const simulateDirectBridgeNativeOnStargateL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.STARGATE_L1;
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
        const srcPoolId = 0;
        const dstPoolId = 0;
        const minReceivedAmt = ethers.utils.parseEther('0.01');
        const optionalValue = ethers.utils.parseEther('0.01');
        //optimism ChainId
        const stargateDstChainId = 111;
        const destinationGasLimit = 0;
        const destinationPayload = "0x";
        const value = bridgingAmount;
        const gasReserve = ethers.utils.parseEther('0.2');

        const routerAddress = '0x150f94B44927F078737562f0fcF3C95c01Cc2376';
        const senderSigner = provider.getSigner(sender);
        await flushNativeBalance(provider, sender);
        await addNativeBalance(provider, sender, bridgingAmount.add(optionalValue).add(gasReserve));

        const abiCoder = ethers.utils.defaultAbiCoder;
        const encodedRecipient = abiCoder.encode(
            ["address"], // encode as address
            [recipient]); // address to encode

        const IBridgeStargateInstance = new ethers.Contract(routerAddress, IRouterEth.abi, senderSigner);
        
        const bridgeTxn = await IBridgeStargateInstance.swapETH(
            stargateDstChainId, 
            sender,
            encodedRecipient,
            BigNumber.from(bridgingAmount),
            BigNumber.from(minReceivedAmt),
            {
                value: bridgingAmount.add(optionalValue),
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        console.log(`txnReceipt is: ${JSON.stringify(txnReceipt, null, 2)}`);

        if (!txnReceipt.status) {
            throw new Error("stargateL1Route Native-Direct-Bridge simulation failed");
        }

        gasUsed = txnReceipt.gasUsed.toString();
    } catch (e) {
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
