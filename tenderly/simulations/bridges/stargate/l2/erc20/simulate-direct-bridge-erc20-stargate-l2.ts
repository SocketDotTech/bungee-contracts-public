import { ethers, BigNumber } from 'ethers';
import * as IBridgeStargateABI from "../../../../../../abi/bridges/stargate/IBridgeStargate.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { flushERC20 } from '../../../../../helper/flush-erc20';

export const simulateDirectBridgeERC20OnStargateL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.STARGATE_L2;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 300000000;
        const minReceivedAmt = 290000000;
        const srcPoolId = 1;
        const dstPoolId = 1;
        //optimism ChainId
        const stargateDstChainId = 111;
        const destinationGasLimit = 0;
        const destinationPayload = "0x";
        const value = ethers.utils.parseEther('1');
        const gasReserve = ethers.utils.parseEther('1');

        const senderSigner = provider.getSigner(sender);

        const usdc_whale = '0xC070A61D043189D99bbf4baA58226bf0991c7b11';
        await flushERC20(provider, token, sender);
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);

        const routerAddress = '0x45A01E4e04F14f7A4a6702c74187c5F6222033cd';
        await addERC20Allowance(provider, token, sender, routerAddress, bridgingAmount);
        await addNativeBalance(provider, sender, value.add(gasReserve));

        const abiCoder = ethers.utils.defaultAbiCoder;
        const encodedRecipient = abiCoder.encode(
            ["address"], // encode as address
            [recipient]); // address to encode

        const IBridgeStargateInstance = new ethers.Contract(routerAddress, IBridgeStargateABI.abi, senderSigner);
        
        const bridgeTxn = await IBridgeStargateInstance.swap(
            stargateDstChainId, 
            srcPoolId,  
            dstPoolId,
            sender,
            BigNumber.from(bridgingAmount),
            BigNumber.from(minReceivedAmt),
            [destinationGasLimit, 0, "0x"],
            encodedRecipient,
            destinationPayload,
            {
                value: value,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        console.log(`txnReceipt is: ${JSON.stringify(txnReceipt)}`);

        if (!txnReceipt.status) {
            throw new Error("stargateL2Route ERC20-Direct-Bridge simulation failed");
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
