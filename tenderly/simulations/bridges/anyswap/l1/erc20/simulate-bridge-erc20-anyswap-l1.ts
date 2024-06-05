import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployAnySwapRoute } from "../../../../../deployments/bridges/anyswap-v4/l1/deploy-anyswap-l1-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as AnySwapL1ABI from "../../../../../../abi/bridges/anyswap-v4/l1/AnySwapL1.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { flushERC20 } from '../../../../../helper/flush-erc20';
import { flushNativeBalance } from '../../../../../helper/flush-native-balance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { getNativeBalance } from '../../../../../helper/get-native-balance';

export const simulateBridgeERC20OnAnySwapL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes,sender: string,  socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.ANYSWAP_V4_L1;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;
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

        // deploy AnySwapL1 Arbitrum
        const anySwapL1Instance = await deployAnySwapRoute(provider, socketGatewayAddress, sender);
        const anySwapL1RouteAddress = anySwapL1Instance.address;

        // add anySwapL1 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, anySwapL1RouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 100000000;        
        const ANY_SWAP_USDC = '0x7EA2be2df7BA6E54B1A9C70676f668455E329d29';

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await flushERC20(provider, token, sender);
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, socketGatewayAddress, bridgingAmount);

        const bridgeAbiInterface = new ethers.utils.Interface(AnySwapL1ABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20ExternalTo',
            [[bridgingAmount, destinationChainId, recipient, token, ANY_SWAP_USDC]]);

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("AnySwapL1 ERC20-Bridge simulation failed");
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
