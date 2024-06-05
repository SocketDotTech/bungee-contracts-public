import { ChainCodeToChainId, ChainCodes } from "../../../../../static-data/ll-static-data";
import { createFork } from "../../../../helper/create-fork";
import { deleteForkById } from "../../../../helper/delete-fork-id";
import { simulateBridgeERC20OnNativeOptimism } from "../../../bridges/native-optimism/simulate-bridge-erc20-nativeoptimism";

export const executeNativeOptimismERC20Bridge = async (sourceChain: ChainCodes, destinationChain: ChainCodes, forkBlockNumber: number, sender: string) => {
   const owner = '0x2FA81527389929Ae9FD0f9ACa9e16Cba37D3EeA1';
   const fork = await createFork(ChainCodeToChainId.get(sourceChain) as number, forkBlockNumber);
   const forkProvider = fork.forkProvider;
   const forkId = fork.forkId;
   
   const simulationResponse = await simulateBridgeERC20OnNativeOptimism(forkProvider, fork.forkAtBlockNumber, sourceChain, destinationChain, sender, owner);
   deleteForkById(forkId);

   return simulationResponse;
};