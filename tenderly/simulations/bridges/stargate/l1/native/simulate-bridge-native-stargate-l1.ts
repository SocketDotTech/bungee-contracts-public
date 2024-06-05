import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployStargateL1Route } from "../../../../../deployments/bridges/stargate/l1/deploy-stargate-l1-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as StargateImplL1ABI from "../../../../../../abi/bridges/stargate/l1/StargateImplL1.json";
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { flushNativeBalance } from '../../../../../helper/flush-native-balance';

export const simulateBridgeNativeOnStargateL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.STARGATE_L1;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        // deploy socketgateway
        const socketGatewayInstance = await deploySocketGateway(provider, sender, socketGatewayOwner);
        const socketGatewayAddress = socketGatewayInstance.address;

        // deploy StargateL1 Arbitrum
        const stargateL1Instance = await deployStargateL1Route(provider, socketGatewayAddress, sender);
        const stargateL1RouteAddress = stargateL1Instance.address;

        // add StargateL1 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, stargateL1RouteAddress);

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

        const senderSigner = provider.getSigner(sender);
        await flushNativeBalance(provider, sender);
        await addNativeBalance(provider, sender, bridgingAmount.add(optionalValue).add(gasReserve));

        const bridgeAbiInterface = new ethers.utils.Interface(StargateImplL1ABI.abi);
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
            throw new Error("stargateL1Route Native-Bridge simulation failed");
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
