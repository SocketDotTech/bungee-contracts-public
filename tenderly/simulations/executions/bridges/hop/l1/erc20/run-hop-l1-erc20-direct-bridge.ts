import { ChainCodeToChainId, ChainCodes } from "../../../../../../../static-data/ll-static-data";
import { createFork } from "../../../../../../helper/create-fork";
import { deleteForkById } from "../../../../../../helper/delete-fork-id";
import { simulateDirectBridgeERC20OnHopL1 } from "../../../../../bridges/hop/l1/erc20/simulate-direct-bridge-erc20-hop-l1";

export const executeHopL1ERC20DirectBridge = async (sourceChain: ChainCodes, destinationChain: ChainCodes, forkBlockNumber: number, sender: string) => {
   const fork = await createFork(ChainCodeToChainId.get(sourceChain) as number, forkBlockNumber);
   const forkProvider = fork.forkProvider;
   const forkId = fork.forkId;
   
   const simulationResponse = await simulateDirectBridgeERC20OnHopL1(forkProvider, fork.forkAtBlockNumber, sourceChain, destinationChain, sender);
   deleteForkById(forkId);

   return simulationResponse;
};