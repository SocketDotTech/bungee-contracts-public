import { ChainCodeToChainId, ChainCodes } from "../../../../../../static-data/ll-static-data";
import { createFork } from "../../../../../helper/create-fork";
import { deleteForkById } from "../../../../../helper/delete-fork-id";
import { simulateDirectBridgeNativeOnAcross } from "../../../../bridges/across/native/simulate-direct-bridge-native-across";

export const executeAcrossNativeDirectBridge = async (sourceChain: ChainCodes, destinationChain: ChainCodes, forkBlockNumber: number, sender: string) => {
   const fork = await createFork(ChainCodeToChainId.get(sourceChain) as number, forkBlockNumber);
   const forkProvider = fork.forkProvider;
   const forkId = fork.forkId;
   
   //Eth
   const simulationResponse = await simulateDirectBridgeNativeOnAcross(forkProvider, fork.forkAtBlockNumber, sourceChain, destinationChain, sender);
   deleteForkById(forkId);

   return simulationResponse;
};