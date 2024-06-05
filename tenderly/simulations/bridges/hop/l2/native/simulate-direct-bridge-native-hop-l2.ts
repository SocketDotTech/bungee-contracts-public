import { BigNumber, ethers } from 'ethers';
import * as HopAMMABI from "../../../../../../abi/bridges/hop/HopAMM.json";
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { NATIVE_TOKEN_ADDRESS, ChainCodes, ChainCodeToChainId, BridgeType, BridgeCodes, TokenType, TokenCodes, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { getNativeBalance } from '../../../../../helper/get-native-balance';

export const simulateDirectBridgeNativeOnHopL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {

    const token = NATIVE_TOKEN_ADDRESS;
    const sourceChainId = ChainCodeToChainId.get(sourceChain);
    const destinationChainId = ChainCodeToChainId.get(destinationChain);
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.HOP_L2;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const _hopAMM = '0x884d1Aa15F9957E1aEAA86a82a72e49Bc2bfCbe3';
        // fees passed to relayer
        const _bonderFee = BigNumber.from("200000000000000000")
        const _amountOutMin = ethers.utils.parseEther('15');
        const block_timestamp = Date.now();
        const _deadline = block_timestamp + 60 * 20;
        const _deadlineDestination = block_timestamp + 60 * 20;
        const _amountOutMinDestination = ethers.utils.parseEther('15');
        const bridgingAmount = ethers.utils.parseEther('20');

        const senderSigner = provider.getSigner(sender);

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
                value: bridgingAmount,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);
        if (!txnReceipt.status) {
            throw new Error("HopL2 Native-Direct-Bridge simulation failed");
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
