import { ethers } from 'ethers';
import { addRoute } from "../../../../deployments/add-route";
import { deployCBridgeRoute } from "../../../../deployments/bridges/cbridge/deploy-cbridge-route";
import { deploySocketGateway } from "../../../../deployments/deploy-socket-gateway";
import * as CelerImplABI from "../../../../../abi/bridges/cbridge/CelerImpl.json";
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { flushNativeBalance } from '../../../../helper/flush-native-balance';

export const simulateBridgeNativeOnCBridge = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes,sender: string,  socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.CBRIDGE;
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
        const cbridgeInstance = await deployCBridgeRoute(provider, socketGatewayAddress, sender);
        const cbridgeRouteAddress = cbridgeInstance.address;

        // add cbridge-route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, cbridgeRouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = ethers.utils.parseEther('1');
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const nonce = block_timestamp;
        const maxSlippage = 5000;

        const senderSigner = provider.getSigner(sender);
        await flushNativeBalance(provider, sender);

        const gasReserve = ethers.utils.parseEther('0.1');
        await addNativeBalance(provider, sender, bridgingAmount.add(gasReserve));

        const bridgeAbiInterface = new ethers.utils.Interface(CelerImplABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeNativeExternalTo',
            [[recipient, token, bridgingAmount, destinationChainId, nonce, maxSlippage]]);

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                value: bridgingAmount,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("CBridge Native-Bridge simulation failed");
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
        sourceChainCode: ChainCodes[sourceChain],
        sourceChainId: sourceChainId,
        destinationChainCode: ChainCodes[destinationChain],
        destinationChainId: destinationChainId,
        tokenAddress: token
      });
}
