import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployStargateL2Route } from "../../../../../deployments/bridges/stargate/l2/deploy-stargate-l2-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as StargateImplL2ABI from "../../../../../../abi/bridges/stargate/l2/StargateImplL2.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { flushERC20 } from '../../../../../helper/flush-erc20';

export const simulateBridgeERC20OnStargateL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.STARGATE_L2;
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

        // deploy StargateL2 Arbitrum
        const stargateL2Instance = await deployStargateL2Route(provider, socketGatewayAddress, sender);
        const stargateL2RouteAddress = stargateL2Instance.address;

        // add StargateL2 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, stargateL2RouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 300000000;
        const srcPoolId = 1;
        const dstPoolId = 1;
        const minReceivedAmt = 290000000;
        const optionalValue = 0;
        //optimism ChainId
        const stargateDstChainId = 111;
        const destinationGasLimit = 0;
        const destinationPayload = "0x";
        const value = ethers.utils.parseEther('1');
        const gasReserve = ethers.utils.parseEther('0.1');

        const senderSigner = provider.getSigner(sender);

        const usdc_whale = '0xC070A61D043189D99bbf4baA58226bf0991c7b11';
        // await flushERC20(provider, token, sender);
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, socketGatewayAddress, bridgingAmount);
        await addNativeBalance(provider, sender, value.add(gasReserve));

        const bridgeAbiInterface = new ethers.utils.Interface(StargateImplL2ABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20ExternalTo',
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
                value: value,
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("stargateL2Route ERC20-Bridge simulation failed");
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
