import { BigNumber, ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployHopL1Route } from "../../../../../deployments/bridges/hop/l1/deploy-hop-l1-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as HopL1ABI from "../../../../../../abi/bridges/hop/l1/HopL1.json";
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { ChainCodes, NATIVE_TOKEN_ADDRESS, ChainCodeToChainId, BridgeType, BridgeCodes, TokenType, TokenCodes, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { getNativeBalance } from '../../../../../helper/get-native-balance';
import { flushNativeBalance } from '../../../../../helper/flush-native-balance';

export const simulateBridgeNativeOnHopL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.HOP_L1;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    const token: string = NATIVE_TOKEN_ADDRESS;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        // deploy socketgateway
        const socketGatewayInstance = await deploySocketGateway(provider, sender, socketGatewayOwner);
        const socketGatewayAddress = socketGatewayInstance.address;

        // deploy HopL1 Arbitrum
        const hopL1Instance = await deployHopL1Route(provider, socketGatewayAddress, sender);
        const hopL1RouteAddress = hopL1Instance.address;

        // add HopL1 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, hopL1RouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";

        const _l1bridgeAddr = '0xb8901acB165ed027E32754E0FFe830802919727f';
        const _relayer = '0x0000000000000000000000000000000000000000';
        const _amountOutMin = 0;
        const _relayerFee = 0;
        const _deadline = 0;
        const bridgingAmount = ethers.utils.parseEther('1');
        const gasReserve = BigNumber.from(ethers.utils.parseEther('0.02'));

        //sequence of arguments for implData: receiverAddress, token, l1BridgeAddress, relayer, destinationChainId, bridgingAmount, amountOutMin, relayerFees, deadline
        const bridgeAbiInterface = new ethers.utils.Interface(HopL1ABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeNativeExternalTo',
            [[recipient, token, _l1bridgeAddr, 
              _relayer, destinationChainId, bridgingAmount, 
              _amountOutMin, _relayerFee, _deadline]]);

        const senderSigner = provider.getSigner(sender);
        await flushNativeBalance(provider, sender);
        await addNativeBalance(provider, sender, bridgingAmount.add(gasReserve));

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                value: bridgingAmount,
                gasLimit: 200000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        gasUsed = txnReceipt.gasUsed.toString();    

        if (!txnReceipt.status) {
            throw new Error("HopL1 Native-Bridge simulation failed");
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
