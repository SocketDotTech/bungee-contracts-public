import { BridgeCodes, BridgeType, ChainCodeToChainId, POLYGON_CHAIN_ID, TokenType } from "../../static-data/ll-static-data";
import { deleteForkById } from "../helper/delete-fork-id";
import {getERC20Balance} from "../helper/get-erc20-balance";
import { getForkProviderForNetwork } from "../helper/get-fork-provider";
import { ChainCodes, Tokens, TokenCodes } from '../../static-data/ll-static-data';

//usage: npx ts-node tenderly/commands/command-get-erc20-balance.ts
(async () => {   
   const sourceChainCode: ChainCodes = ChainCodes.ETH;
   const tokenCode: TokenCodes = TokenCodes.USDC;
   //@ts-ignore
   const token = Tokens.get(tokenCode).get(sourceChain) as string;

   const account = "0xDa9CE944a37d218c3302F6B82a094844C6ECEb17";

   const eth_networkId = 1;
   const eth_providerResponse = await getForkProviderForNetwork(eth_networkId);
   const eth_provider = eth_providerResponse.provider;

   const erc20Balance = await getERC20Balance(eth_provider, token, account);
   console.log(`erc20Balance is : ${erc20Balance}`);
})().catch((e) => {
   console.error('error: ', e);
});