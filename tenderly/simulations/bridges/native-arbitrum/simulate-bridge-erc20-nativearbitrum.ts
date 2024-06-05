import { ethers } from 'ethers';
import { addRoute } from "../../../deployments/add-route";
import { deployNativeArbitrumRoute } from "../../../deployments/bridges/native-arbitrum/deploy-native-arbitrum-route";
import { deploySocketGateway } from "../../../deployments/deploy-socket-gateway";
import * as NativeArbitrumABI from "../../../../abi/bridges/native-arbitrum/NativeArbitrum.json";
import { addERC20Allowance } from '../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../helper/add-native-balance';
import { transferERC20 } from '../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, SimulationResponse, TokenCodes, Tokens, TokenType } from '../../../../static-data/ll-static-data';

export const simulateBridgeERC20OnNativeArbitrum = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.NATIVE_ARBITRUM;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;

    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {

        // deploy socketgateway
        const socketGatewayInstance = await deploySocketGateway(provider, sender, socketGatewayOwner);
        const socketGatewayAddress = socketGatewayInstance.address;

        // deploy Native Arbitrum
        const nativeArbitrumInstance = await deployNativeArbitrumRoute(provider, socketGatewayAddress, sender);
        const nativeArbitrumRouteAddress = nativeArbitrumInstance.address;

        // add Native Optimism route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, nativeArbitrumRouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const gatewayAddress = '0xcEe284F754E854890e311e3280b767F80797180d';
        const maxGas = 357500;
        const gasPriceBid = 300000000;
        const data = "0x000000000000000000000000000000000000000000000000000097d65f01cc4000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000";
        const bridgingAmount = 1000000000;
        const bridgeValue = 274196972748864;

        //sequence of arguments for implData: receiverAddress, token, gatewayAddress, amount, value, maxGas, gasPriceBid, data
        const bridgeAbiInterface = new ethers.utils.Interface(NativeArbitrumABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20ExternalTo',
            [[recipient, token, gatewayAddress, bridgingAmount, bridgeValue, maxGas, gasPriceBid, data]]);

        const senderSigner = provider.getSigner(sender);

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, socketGatewayAddress, bridgingAmount);

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                value: bridgeValue,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("NativeArbitrum ERC20-Bridge simulation failed");
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
