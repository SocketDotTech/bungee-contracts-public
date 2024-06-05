import {addERC20Balance} from "../helper/add-erc20-to-account";
import { deleteForkById } from "../helper/delete-fork-id";
import { getERC20Balance } from "../helper/get-erc20-balance";
import { getForkProvider } from "../helper/get-fork-provider";

//usage: npx ts-node tenderly/commands/fund-account-with-dai.ts
(async () => {
   const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
   const account = "0xE1bbb71cc9E476317DFcE210Eb760D5Bc29D8709";
   const tokenAmount = 100000000;

   const forkIdProviderResponse = await getForkProvider(1, 14386016);
   const provider = forkIdProviderResponse.provider;
   const forkId = forkIdProviderResponse.forkId;
   const txn = await addERC20Balance(provider, DAI_ADDRESS, account,tokenAmount);

   const erc20Balance = await getERC20Balance(provider, DAI_ADDRESS, account);

   await deleteForkById(forkId);

   if(erc20Balance != tokenAmount){
      throw new Error(`Failed to fund account: ${account} with token amount ${tokenAmount}`);
   }

})().catch((e) => {
   console.error('error: ', e);
});