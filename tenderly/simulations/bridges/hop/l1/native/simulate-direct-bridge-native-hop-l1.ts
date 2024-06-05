import { BigNumber, ethers } from 'ethers';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import * as HopL1BridgeABI from "../../../../../../abi/bridges/hop/HopL1Bridge.json";
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, NATIVE_TOKEN_ADDRESS, SimulationResponse, TokenCodes, TokenType } from '../../../../../../static-data/ll-static-data';
import { getNativeBalance } from '../../../../../helper/get-native-balance';

export const simulateDirectBridgeNativeOnHopL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.HOP_L1;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    const token: string = NATIVE_TOKEN_ADDRESS;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const _l1bridgeAddr = '0xb8901acB165ed027E32754E0FFe830802919727f';
        const _relayer = '0x0000000000000000000000000000000000000000';
        const _amountOutMin = 0;
        const _relayerFee = 0;
        const _deadline = 0;
        const bridgingAmount = ethers.utils.parseEther('1');

        const senderSigner = provider.getSigner(sender);
        await addNativeBalance(provider, sender, ethers.utils.parseEther('1.2'));

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
                value: bridgingAmount,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);
        gasUsed = txnReceipt.gasUsed.toString();

        if (!txnReceipt.status) {
            throw new Error("HopL1 Native-Direct-Bridge simulation failed");
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
