import {ethers} from "ethers";
import { getForkProvider } from "../helper/get-fork-provider";
import { deleteForkById } from "../helper/delete-fork-id";
import {addNativeBalance} from "../helper/add-native-balance";

// usage: npx ts-node tenderly/commands/transfer-eth-on-fork.ts
(async () => {
   const forkIdProviderResponse = await getForkProvider(1, 14386016);
   const provider = forkIdProviderResponse.provider;
   const forkId = forkIdProviderResponse.forkId;

   await addNativeBalance(provider, '0xE1bbb71cc9E476317DFcE210Eb760D5Bc29D8709', ethers.utils.parseEther('1'));

   await deleteForkById(forkId);
})().catch((e) => {
   console.error('error: ', e);
});