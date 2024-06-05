import {ethers} from 'ethers';
import {addERC20Allowance} from "../helper/add-erc20-allowance";
import { addERC20Balance } from "../helper/add-erc20-to-account";
import { deleteForkById } from "../helper/delete-fork-id";
import { getERC20Balance } from "../helper/get-erc20-balance";
import { getForkProvider } from "../helper/get-fork-provider";
import { addNativeBalance } from '../helper/add-native-balance';
import { transferERC20 } from '../helper/transfer-erc20';

//usage: npx ts-node tenderly/commands/run-transfer-erc20.ts
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

   const recipient = '0xcb7387fCC70801619678842d11F007e847DBd2e7';
   const transferAmount = 100000000;

   const recipientBalanceBeforeTransfer = await getERC20Balance(provider, DAI_ADDRESS, recipient);
   console.log(`Balance of recipient ${recipient} before transfer is: ${recipientBalanceBeforeTransfer}`);

   await transferERC20(provider, DAI_ADDRESS, account, recipient, transferAmount);

   const recipientBalanceAfterTransfer = await getERC20Balance(provider, DAI_ADDRESS, recipient);
   console.log(`Balance of recipient ${recipient} after transfer is: ${recipientBalanceAfterTransfer}`);

   await deleteForkById(forkId);
})().catch((e) => {
   console.error('error: ', e);
});
