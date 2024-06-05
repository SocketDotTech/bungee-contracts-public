import { ethers } from 'ethers';
import * as AnySwapV3RouterABI from "../../../../../../abi/bridges/anyswap-v4/AnySwapV3Router.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';

export const simulateDirectBridgeERC20OnAnySwapL1 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.ANYSWAP_V4_L1;
    const tokenType: TokenType = TokenType.ERC20;
    const tokenCode: TokenCodes = TokenCodes.USDC;
    //@ts-ignore
    const token = Tokens.get(tokenCode).get(sourceChain) as string;
    let gasUsed = 0;
    let isSuccessful = true;
    let errorMessage = "";

    try {
        const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
        const bridgingAmount = 100000000;
        const ANY_SWAP_USDC = '0x7EA2be2df7BA6E54B1A9C70676f668455E329d29';

        const senderSigner = provider.getSigner(sender);

        const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);

        const routerAddress = '0x6b7a87899490EcE95443e979cA9485CBE7E71522';
        await addERC20Allowance(provider, token, sender, routerAddress, bridgingAmount);

        const anySwapV3RouterInstance = new ethers.Contract(routerAddress, AnySwapV3RouterABI.abi, senderSigner);
        const bridgeTxn = await anySwapV3RouterInstance.anySwapOutUnderlying(ANY_SWAP_USDC, recipient, bridgingAmount, destinationChainId,
        {
            gasLimit: 600000,
            gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
        });

        const bridgeTxnHash = bridgeTxn.hash;

        const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

        if (!txnReceipt.status) {
            throw new Error("AnySwapL1 ERC20-Direct-Bridge simulation failed");
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
