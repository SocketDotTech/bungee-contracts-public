import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployHopL1Route } from "../../../../../deployments/bridges/hop/l1/deploy-hop-l1-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as HopL1ABI from "../../../../../../out/HopImplL1.sol/HopImplL1.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';

export const simulateBridgeERC20OnHopL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.HOP_L1;
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

        // deploy HopL1 Arbitrum
        const hopL1Instance = await deployHopL1Route(provider, socketGatewayAddress, sender);
        const hopL1RouteAddress = hopL1Instance.address;

        console.log(hopL1RouteAddress);

        // add HopL1 route to SocketGateway
        await addRoute(provider, socketGatewayAddress, socketGatewayOwner, hopL1RouteAddress);

        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 100000000;
        const _l1bridgeAddr = '0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a';
        const _relayer = '0x0000000000000000000000000000000000000000';
        const _amountOutMin = 90000000;
        const _relayerFee = 0;
        const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
        const _deadline = block_timestamp + 100000;

        //sequence of arguments for implData: receiverAddress, token, gatewayAddress, amount, value, maxGas, gasPriceBid, data
        const bridgeAbiInterface = new ethers.utils.Interface(HopL1ABI.abi);
        const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20To',
            [recipient, token, _l1bridgeAddr, _relayer, destinationChainId, bridgingAmount, _amountOutMin, _relayerFee, _deadline]);

        const senderSigner = provider.getSigner(sender);

        await addNativeBalance(provider, sender, ethers.utils.parseEther('1'));

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await transferERC20(provider, token!, usdc_whale, sender, bridgingAmount);

        await addERC20Allowance(provider, token!, sender, socketGatewayAddress, bridgingAmount);

        // const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
        //     {
        //         gasLimit: 600000,
        //         gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
        //     });

        // const bridgeTxnHash = bridgeTxn.hash;

        const mergeData = `0x000001E3${bridgeImplData.slice(2)}`

        const transactionParameters = [{
            to: socketGatewayAddress,
            from: sender,
            data: mergeData,
            gas: ethers.utils.hexValue(3000000),
            gasPrice: ethers.utils.hexValue(1),
            value: ethers.utils.hexValue(0)
        }];
    
        const bridgeTxnHash = await provider.send('eth_sendTransaction', transactionParameters);

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("HopL1 ERC20-Bridge simulation failed");
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
