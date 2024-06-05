import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployAnySwapL2Route } from "../../../../../deployments/bridges/anyswap-v4/l2/deploy-anyswap-l2-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as AnySwapL2ABI from "../../../../../../abi/bridges/anyswap-v4/l2/AnySwapL2.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';

export const simulateBridgeERC20OnAnySwapL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.ANYSWAP_V4_L2;
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

        // deploy AnySwapL2 Arbitrum
        const anySwapL2Instance = await deployAnySwapL2Route(provider, socketGatewayAddress, sender);
        const anySwapL2RouteAddress = anySwapL2Instance.address;

        // add anySwapL1 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, anySwapL2RouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 100000000;        
        const ANY_SWAP_USDC = '0xd69b31c3225728CC57ddaf9be532a4ee1620Be51';

        const senderSigner = provider.getSigner(sender);

        const usdc_whale = '0xC070A61D043189D99bbf4baA58226bf0991c7b11';
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, socketGatewayAddress, bridgingAmount);

        const bridgeAbiInterface = new ethers.utils.Interface(AnySwapL2ABI.abi);
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
            throw new Error("AnySwapL2 ERC20-Bridge simulation failed");
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
