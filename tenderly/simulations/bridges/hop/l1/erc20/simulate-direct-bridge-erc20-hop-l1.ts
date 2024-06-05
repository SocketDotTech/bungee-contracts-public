import { ethers } from 'ethers';
import * as HopL1BridgeABI from "../../../../../../abi/bridges/hop/HopL1Bridge.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { ChainCodes, ChainCodeToChainId, Tokens, TokenCodes, BridgeType, BridgeCodes, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';

export const simulateDirectBridgeERC20OnHopL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.HOP_L1;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const _l1bridgeAddr = '0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a';
        const _relayer = '0x0000000000000000000000000000000000000000';
        const _amountOutMin = 90000000;
        const _relayerFee = 0;
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const _deadline = block_timestamp + 100000;
        const bridgingAmount = 100000000;

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('0.1'));

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, _l1bridgeAddr, bridgingAmount);

        const hopL1BridgeInstance = new ethers.Contract(_l1bridgeAddr, HopL1BridgeABI.abi, senderSigner);
        const bridgeTxn = await hopL1BridgeInstance.sendToL2(
            destinationChainId,
            recipient,
            bridgingAmount,
            _amountOutMin,
            _deadline,
            _relayer,
            _relayerFee,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        gasUsed = txnReceipt.gasUsed.toString();

        if (!txnReceipt.status) {
            throw new Error("HopL1 ERC20-Direct-Bridge simulation failed");
        }
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
