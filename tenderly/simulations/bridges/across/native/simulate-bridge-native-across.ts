import { BigNumber, ethers } from 'ethers';
import { addRoute } from "../../../../deployments/add-route";
import { deployAcrossRoute } from "../../../../deployments/bridges/across/deploy-across-route";
import { deploySocketGateway } from "../../../../deployments/deploy-socket-gateway";
import * as AcrossABI from "../../../../../abi/bridges/across/Across.json";
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { getNativeBalance } from '../../../../helper/get-native-balance';

export const simulateBridgeNativeOnAcross = async (provider: any, forkBlockNumber: number, sourceChainCode: ChainCodes, destinationChainCode: ChainCodes, sender: string, socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChainCode) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChainCode) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.ACROSS;
    const tokenType: TokenType = TokenType.NATIVE;
    const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChainCode) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        // deploy socketgateway
        const socketGatewayInstance = await deploySocketGateway(provider, sender, socketGatewayOwner);
        const socketGatewayAddress = socketGatewayInstance.address;

        // deploy Across on ETH
        const acrossInstance = await deployAcrossRoute(provider, socketGatewayAddress, sender);
        const acrossRouteAddress = acrossInstance.address;

        // add Across-route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, acrossRouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const _relayerFeePct = ethers.BigNumber.from(0);
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const _quoteTimestamp = ethers.BigNumber.from(block_timestamp);
        const bridgingAmount = ethers.utils.parseEther('1');
        const gasReserve =  ethers.utils.parseEther('0.2');

        const bridgeAbiInterface = new ethers.utils.Interface(AcrossABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeNativeExternalTo',
            [[bridgingAmount, destinationChainId, recipient, token, _quoteTimestamp, _relayerFeePct]]);

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, bridgingAmount.add(gasReserve));

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                value: bridgingAmount,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("Across Native-Bridge simulation failed");
        }

        gasUsed = txnReceipt.gasUsed.toString();    
    } catch (e) {
        console.error(`${e}`);
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
        sourceChainCode: ChainCodes[sourceChainCode],
        sourceChainId: sourceChainId,
        destinationChainCode: ChainCodes[destinationChainCode],
        destinationChainId: destinationChainId,
        tokenAddress: token
      });
}
