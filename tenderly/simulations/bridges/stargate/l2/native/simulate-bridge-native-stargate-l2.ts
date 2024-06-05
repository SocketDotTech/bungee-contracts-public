import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployStargateL2Route } from "../../../../../deployments/bridges/stargate/l2/deploy-stargate-l2-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as StargateImplL2ABI from "../../../../../../abi/bridges/stargate/l2/StargateImplL2.json";
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { flushNativeBalance } from '../../../../../helper/flush-native-balance';
import { getNativeBalance } from '../../../../../helper/get-native-balance';

export const simulateBridgeNativeOnStargateL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.STARGATE_L2;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const senderSigner = provider.getSigner(sender);

        // deploy socketgateway
        const socketGatewayInstance = await deploySocketGateway(provider, sender, socketGatewayOwner);
        const socketGatewayAddress = socketGatewayInstance.address;

        // deploy StargateL2 Arbitrum
        const stargateL2Instance = await deployStargateL2Route(provider, socketGatewayAddress, sender);
        const stargateL2RouteAddress = stargateL2Instance.address;

        // add StargateL2 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, stargateL2RouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = ethers.utils.parseEther('1');
        const srcPoolId = 13;
        const dstPoolId = 13;
        const minReceivedAmt = ethers.utils.parseEther('0.01');
        const optionalValue = ethers.utils.parseEther('0.05');
        //optimism ChainId
        const stargateDstChainId = 110;
        const destinationGasLimit = 0;
        const destinationPayload = "0x";
        const value = bridgingAmount;

        const bridgeAbiInterface = new ethers.utils.Interface(StargateImplL2ABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeNativeExternalTo',
            [[recipient,
                token,
                sender,
                bridgingAmount,
                value,
                srcPoolId,
                dstPoolId,
                minReceivedAmt,
                optionalValue,
                destinationGasLimit,
                stargateDstChainId,
                destinationPayload]]);

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                value: bridgingAmount.add(optionalValue),
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("stargateL2Route Native-Bridge simulation failed");
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
