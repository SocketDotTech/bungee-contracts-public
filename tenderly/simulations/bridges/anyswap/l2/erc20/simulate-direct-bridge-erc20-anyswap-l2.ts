import { ethers } from 'ethers';
import * as AnySwapV3RouterABI from "../../../../../../abi/bridges/anyswap-v4/AnySwapV3Router.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, TokenCodes, Tokens, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';

export const simulateDirectBridgeERC20OnAnySwapL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string) => {

    const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
    const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
    const bridgeType: BridgeType = BridgeType.DIRECT_BRIDGE;
    const bridgeName: BridgeCodes = BridgeCodes.ANYSWAP_V4_L2;
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
        const ANY_SWAP_USDC = '0xd69b31c3225728CC57ddaf9be532a4ee1620Be51';

        const senderSigner = provider.getSigner(sender);

        const usdc_whale = '0xC070A61D043189D99bbf4baA58226bf0991c7b11';
        await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);

        const routerAddress = '0x4f3Aff3A747fCADe12598081e80c6605A8be192F';
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
