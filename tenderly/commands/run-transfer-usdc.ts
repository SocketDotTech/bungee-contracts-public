import {ethers} from 'ethers';
import {addERC20Allowance} from "../helper/add-erc20-allowance";
import { addERC20Balance } from "../helper/add-erc20-to-account";
import { deleteForkById } from "../helper/delete-fork-id";
import { getERC20Balance } from "../helper/get-erc20-balance";
import { getForkProvider } from "../helper/get-fork-provider";
import { addNativeBalance } from '../helper/add-native-balance';
import { transferERC20 } from '../helper/transfer-erc20';

//usage: npx ts-node tenderly/commands/run-transfer-usdc.ts
(async () => {
   const USDC_Eth = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
   const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
   const tokenAmount = 100000000;

   const forkIdProviderResponse = await getForkProvider(1, 14386016);
   const provider = forkIdProviderResponse.provider;
   const forkId = forkIdProviderResponse.forkId;

   const recipient = '0xcb7387fCC70801619678842d11F007e847DBd2e7';
   const transferAmount = 100000000;

   const recipientBalanceBeforeTransfer = await getERC20Balance(provider, USDC_Eth, recipient);
   console.log(`Balance of recipient ${recipient} before transfer is: ${recipientBalanceBeforeTransfer}`);

   await transferERC20(provider, USDC_Eth, usdc_whale, recipient, transferAmount);

   const recipientBalanceAfterTransfer = await getERC20Balance(provider, USDC_Eth, recipient);
   console.log(`Balance of recipient ${recipient} after transfer is: ${recipientBalanceAfterTransfer}`);

   await deleteForkById(forkId);
})().catch((e) => {
   console.error('error: ', e);
});
