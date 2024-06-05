import { deleteForkById } from "../helper/delete-fork-id";
import {getERC20Allowance} from "../helper/get-erc20-allowance";
import { getForkProvider } from "../helper/get-fork-provider";

//usage: npx ts-node tenderly/commands/command-get-erc20-allowance.ts
(async () => {
   const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
   const providerResponse = await getForkProvider(1, 14386017);
   const provider = providerResponse.provider;
   const owner = '0xE1bbb71cc9E476317DFcE210Eb760D5Bc29D8709';
   const spender = '0xcb7387fCC70801619678842d11F007e847DBd2e7';

   const erc20Allowance = await getERC20Allowance(provider, DAI_ADDRESS, owner, spender);
   console.log(`erc20Allowance is : ${erc20Allowance}`);

   const forkId = providerResponse.forkId;
   await deleteForkById(forkId);
})().catch((e) => {
   console.error('error: ', e);
});