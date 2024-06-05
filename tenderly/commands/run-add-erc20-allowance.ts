import {ethers} from 'ethers';
import {addERC20Allowance} from "../helper/add-erc20-allowance";
import { addERC20Balance } from "../helper/add-erc20-to-account";
import { deleteForkById } from "../helper/delete-fork-id";
import { getERC20Balance } from "../helper/get-erc20-balance";
import { getForkProvider } from "../helper/get-fork-provider";
import { addNativeBalance } from '../helper/add-native-balance';
import { getERC20Allowance } from '../helper/get-erc20-allowance';

//usage: npx ts-node tenderly/commands/run-add-erc20-allowance.ts
(async () => {
   const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
   const account = "0xE1bbb71cc9E476317DFcE210Eb760D5Bc29D8709";
   const tokenAmount = 100000000;

   const forkIdProviderResponse = await getForkProvider(1, 14386016);
   const provider = forkIdProviderResponse.provider;
   const forkId = forkIdProviderResponse.forkId;
   const txn = await addERC20Balance(provider, DAI_ADDRESS, account,tokenAmount);
   const erc20Balance = await getERC20Balance(provider, DAI_ADDRESS, account);
   if(erc20Balance != tokenAmount){
      throw new Error(`Failed to fund account: ${account} with token amount ${tokenAmount}`);
   }

   await addNativeBalance(provider, account,  ethers.utils.parseEther('1'));

   const spender = '0xcb7387fCC70801619678842d11F007e847DBd2e7';
   await addERC20Allowance(provider, DAI_ADDRESS, account, spender, tokenAmount);

   const erc20Allowance = await getERC20Allowance(provider, DAI_ADDRESS, account, spender);
   console.log(`erc20Allowance queried for spender- ${spender} is: ${erc20Allowance}`);

   await deleteForkById(forkId);
})().catch((e) => {
   console.error('error: ', e);
});
