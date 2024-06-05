import { ChainCodeToChainId, ChainCodes } from "../../../../../static-data/ll-static-data";
import { createFork } from "../../../../helper/create-fork";
import { deleteForkById } from "../../../../helper/delete-fork-id";
import { simulateDirectBridgeERC20OnNativeOptimism } from "../../../bridges/native-optimism/simulate-direct-bridge-erc20-nativeoptimism";

export const executeNativeOptimismERC20DirectBridge = async (sourceChain: ChainCodes, destinationChain: ChainCodes, forkBlockNumber: number, sender: string) => {
   const fork = await createFork(ChainCodeToChainId.get(sourceChain) as number, forkBlockNumber);
   const forkProvider = fork.forkProvider;
   const forkId = fork.forkId;
   
   const simulationResponse = await simulateDirectBridgeERC20OnNativeOptimism(forkProvider, fork.forkAtBlockNumber, sourceChain, destinationChain, sender);
   deleteForkById(forkId);

   return simulationResponse;
};