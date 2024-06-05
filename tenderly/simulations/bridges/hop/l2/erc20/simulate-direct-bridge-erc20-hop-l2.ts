import { ethers } from 'ethers';
import * as HopAMMABI from "../../../../../../abi/bridges/hop/HopAMM.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { ChainCodes, ChainCodeToChainId, Tokens, TokenCodes, BridgeType, BridgeCodes, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';

export const simulateDirectBridgeERC20OnHopL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {

    const sourceChainId = ChainCodeToChainId.get(sourceChain);
    const destinationChainId = ChainCodeToChainId.get(destinationChain);
    const bridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName = BridgeCodes.HOP_L2;
    const tokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";
    
    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const _hopAMM = '0x76b22b8C1079A44F1211D867D68b1eda76a635A7';
        // fees passed to relayer
        const _bonderFee = 200000;
        const _amountOutMin = 40000000;
        const block_timestamp = Date.now();
        const _deadline = block_timestamp + 100000;
        const _amountOutMinDestination = 40000000;
        const _deadlineDestination = block_timestamp + 100000;
        const bridgingAmount = 50000000;

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('0.1'));

        const usdc_whale = '0xC070A61D043189D99bbf4baA58226bf0991c7b11';
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, _hopAMM, bridgingAmount);

        const hopAMMInstance = new ethers.Contract(_hopAMM, HopAMMABI.abi, senderSigner);
        const bridgeTxn = await hopAMMInstance.swapAndSend(
            destinationChainId,
            recipient,
            bridgingAmount,
            _bonderFee,
            _amountOutMin,
            _deadline,
            _amountOutMinDestination,
            _deadlineDestination,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("HopL2 ERC20-Direct-Bridge simulation failed");
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
