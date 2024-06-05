import { Contract, ethers } from 'ethers';
import { addERC20Allowance } from '../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../helper/add-native-balance';
import { transferERC20 } from '../../../helper/transfer-erc20';
import * as IRootChainManagerABI from "../../../../abi/bridges/native-polygon/IRootChainManager.json";
import { ChainCodes, TokenCodes, ChainCodeToChainId, Tokens, BridgeType, BridgeCodes, TokenType, SimulationResponse } from '../../../../static-data/ll-static-data';

export const simulateDirectBridgeERC20OnNativePolygon = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.NATIVE_POLYGON;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;

    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const amount = 100000000;
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('1'));

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await transferERC20(provider, token, usdc_whale, sender, amount);
        const erc20PredicateProxy = '0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf';
        await addERC20Allowance(provider, token, sender, erc20PredicateProxy, amount);

        const abiCoder = ethers.utils.defaultAbiCoder;
        const encodedAmount = abiCoder.encode(  ["uint256"], // encode as address
        [amount]); // address to encode

        const rootChainManagerProxy = '0xA0c68C638235ee32657e8f720a23ceC1bFc77C77';
        const rootChainManagerInstance = new Contract(rootChainManagerProxy, IRootChainManagerABI.abi, senderSigner); 
        const bridgeTxn = await rootChainManagerInstance.depositFor(
            recipient, token, encodedAmount,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            }
        );

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("NativePolygon ERC20-Direct-Bridge simulation failed");
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
};
