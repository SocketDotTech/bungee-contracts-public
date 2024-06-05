import {addERC20Balance} from "../helper/add-erc20-to-account";
import { deleteForkById } from "../helper/delete-fork-id";
import { getERC20Balance } from "../helper/get-erc20-balance";
import { getForkProvider } from "../helper/get-fork-provider";

//usage: npx ts-node tenderly/commands/fund-account-with-usdc.ts
(async () => {
   const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
   const account = "0xE1bbb71cc9E476317DFcE210Eb760D5Bc29D8709";
   const tokenAmount = 100000000;

   const forkIdProviderResponse = await getForkProvider(1, 14386016);
   const provider = forkIdProviderResponse.provider;
   const forkId = forkIdProviderResponse.forkId;
   const txn = await addERC20Balance(provider, USDC_ADDRESS, account,tokenAmount);

   const erc20Balance = await getERC20Balance(provider, USDC_ADDRESS, account);
   console.log(`USDC balance is: ${erc20Balance}`);

   await deleteForkById(forkId);

   if(erc20Balance != tokenAmount){
      throw new Error(`Failed to fund account: ${account} with token amount ${tokenAmount}`);
   }

})().catch((e) => {
   console.error('error: ', e);
});