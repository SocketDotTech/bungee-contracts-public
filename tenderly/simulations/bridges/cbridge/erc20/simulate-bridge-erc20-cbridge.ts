import { ethers } from 'ethers';
import { addRoute } from "../../../../deployments/add-route";
import { deployCBridgeRoute } from "../../../../deployments/bridges/cbridge/deploy-cbridge-route";
import { deploySocketGateway } from "../../../../deployments/deploy-socket-gateway";
import * as CelerImplABI from "../../../../../abi/bridges/cbridge/CelerImpl.json";
import { addERC20Allowance } from '../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../static-data/ll-static-data';
import { flushERC20 } from '../../../../helper/flush-erc20';
import { getERC20Balance } from '../../../../helper/get-erc20-balance';
import {getRevertReason} from 'eth-revert-reason';

export const simulateBridgeERC20OnCBridge = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.CBRIDGE;
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

        // deploy hyphenRoute on ETH
        const cbridgeInstance = await deployCBridgeRoute(provider, socketGatewayAddress, sender);
        const cbridgeRouteAddress = cbridgeInstance.address;

        // add cbridge-route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, cbridgeRouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 100000000;
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const nonce = block_timestamp;
        const maxSlippage = 5000;

        const bridgeAbiInterface = new ethers.utils.Interface(CelerImplABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20ExternalTo',
            [[recipient, token, bridgingAmount, destinationChainId, nonce, maxSlippage]]);

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('1'));

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await flushERC20(provider, token, sender);
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);

        await addERC20Allowance(provider, token, sender, socketGatewayAddress, bridgingAmount);

        const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
            {
                gasLimit: 600000,
                gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
            });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            const revertReason = await getRevertReason(bridgeTxnHash);
            console.log(`ReverReason is: ${revertReason}`);
            throw new Error("CBridge ERC20-Bridge simulation failed");
        }

        gasUsed = txnReceipt.gasUsed.toString();

        // const erc20BalanceAfterBridging = await getERC20Balance(provider, token, sender);

        // if(parseInt(erc20BalanceAfterBridging) != 0){
        //     throw new Error("CBridge ERC20-Bridge simulation failed - Assertion on ERC20 Balance after Bridging");
        // }
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
