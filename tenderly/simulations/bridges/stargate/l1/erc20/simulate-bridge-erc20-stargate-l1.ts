import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployStargateL1Route } from "../../../../../deployments/bridges/stargate/l1/deploy-stargate-l1-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as StargateImplL1ABI from "../../../../../../abi/bridges/stargate/l1/StargateImplL1.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { flushERC20 } from '../../../../../helper/flush-erc20';

export const simulateBridgeERC20OnStargateL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.STARGATE_L1;
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

        // deploy StargateL1 Arbitrum
        const stargateL1Instance = await deployStargateL1Route(provider, socketGatewayAddress,sender);
        const stargateL1RouteAddress = stargateL1Instance.address;

        // add StargateL1 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, stargateL1RouteAddress);

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
        const value = ethers.utils.parseEther('0.03');
        const gasReserve = ethers.utils.parseEther('0.01');

        const senderSigner = provider.getSigner(sender);

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        // await flushERC20(provider, token, sender);
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
        await addERC20Allowance(provider, token, sender, socketGatewayAddress, bridgingAmount);
        await addNativeBalance(provider, sender, value.add(gasReserve));

        const bridgeAbiInterface = new ethers.utils.Interface(StargateImplL1ABI.abi);
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
            throw new Error("stargateL1Route ERC20-Bridge simulation failed");
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
