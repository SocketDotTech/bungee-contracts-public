import { ChainCodeToChainId, ChainCodes } from "../../../../../../static-data/ll-static-data";
import { createFork } from "../../../../../helper/create-fork";
import { deleteForkById } from "../../../../../helper/delete-fork-id";
import { simulateDirectBridgeNativeOnHyphen } from "../../../../bridges/hyphen/native/simulate-direct-bridge-native-hyphen";

export const executeHyphenNativeDirectBridge = async (sourceChain: ChainCodes, destinationChain: ChainCodes, forkBlockNumber: number, sender: string) => {
   const fork = await createFork(ChainCodeToChainId.get(sourceChain) as number, forkBlockNumber);
   const forkProvider = fork.forkProvider;
   const forkId = fork.forkId;
   
   const simulationResponse = await simulateDirectBridgeNativeOnHyphen(forkProvider, fork.forkAtBlockNumber, sourceChain, destinationChain, sender);
   deleteForkById(forkId);

   return simulationResponse;
};