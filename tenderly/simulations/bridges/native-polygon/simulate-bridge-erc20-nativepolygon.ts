import { ethers } from 'ethers';
import { addRoute } from "../../../deployments/add-route";
import { deployNativePolygonRoute } from "../../../deployments/bridges/native-polygon/deploy-native-polygon-route";
import { deploySocketGateway } from "../../../deployments/deploy-socket-gateway";
import * as NativePolygonABI from "../../../../abi/bridges/native-polygon/NativePolygon.json";
import { addERC20Allowance } from '../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../helper/add-native-balance';
import { transferERC20 } from '../../../helper/transfer-erc20';
import { ChainCodes, TokenCodes, ChainCodeToChainId, Tokens, BridgeType, BridgeCodes, TokenType, SimulationResponse } from '../../../../static-data/ll-static-data';

export const simulateBridgeERC20OnNativePolygon = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.NATIVE_POLYGON;
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

        // deploy Native Polygon
        const nativePolygonInstance = await deployNativePolygonRoute(provider, socketGatewayAddress, sender);
        const nativePolygonRouteAddress = nativePolygonInstance.address;

        // add Native Polygon route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, nativePolygonRouteAddress);

        const amount = 100000000;
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";

        const bridgeAbiInterface = new ethers.utils.Interface(NativePolygonABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20ExternalTo', [[amount, recipient, token]]);

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('1'));

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await transferERC20(provider, token, usdc_whale, sender, amount);

        await addERC20Allowance(provider, token, sender, socketGatewayAddress, amount);

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("NativePolygon ERC20-Bridge simulation failed");
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
