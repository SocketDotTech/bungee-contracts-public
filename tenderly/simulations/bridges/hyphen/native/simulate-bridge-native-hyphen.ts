import { ethers } from 'ethers';
import { addRoute } from "../../../../deployments/add-route";
import { deployHyphenRoute } from "../../../../deployments/bridges/hyphen/deploy-hyphen-route";
import { deploySocketGateway } from "../../../../deployments/deploy-socket-gateway";
import * as HyphenImplABI from "../../../../../abi/bridges/hyphen/HyphenImpl.json";
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { flushNativeBalance } from '../../../../helper/flush-native-balance';

export const simulateBridgeNativeOnHyphen = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes,sender: string,  socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.HYPHEN;
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

        // deploy hyphenRoute on ETH
        const hyphenInstance = await deployHyphenRoute(provider, socketGatewayAddress, sender);
        const hyphenRouteAddress = hyphenInstance.address;

        // add hyphen-route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, hyphenRouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = ethers.utils.parseEther('1');
        const gasReserve = ethers.utils.parseEther('0.1');

        const bridgeAbiInterface = new ethers.utils.Interface(HyphenImplABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeNativeExternalTo',
            [[bridgingAmount, recipient, token, destinationChainId]]);

        const senderSigner = provider.getSigner(sender);

        await flushNativeBalance(provider, sender);

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
            throw new Error("Hyphen Native-Bridge simulation failed");
        }

        gasUsed = txnReceipt.gasUsed.toString();

        if (!txnReceipt.status) {
            throw new Error("HyphenL1 NativeBride simulation failed");
        }
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
        sourceChainCode: ChainCodes[sourceChain],
        sourceChainId: sourceChainId,
        destinationChainCode: ChainCodes[destinationChain],
        destinationChainId: destinationChainId,
        tokenAddress: token
    });
}
