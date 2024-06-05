import { ChainCodeToChainId, ChainCodes } from "../../../../../../../static-data/ll-static-data";
import { createFork } from "../../../../../../helper/create-fork";
import { deleteForkById } from "../../../../../../helper/delete-fork-id";
import { simulateDirectBridgeERC20OnStargateL2 } from "../../../../../bridges/stargate/l2/erc20/simulate-direct-bridge-erc20-stargate-l2";

export const executeStargateL2ERC20DirectBridge = async (sourceChain: ChainCodes, destinationChain: ChainCodes, forkBlockNumber: number, sender: string) => {
   const fork = await createFork(ChainCodeToChainId.get(sourceChain) as number, forkBlockNumber);
   const forkProvider = fork.forkProvider;
   const forkId = fork.forkId;
   
   const simulationResponse = await simulateDirectBridgeERC20OnStargateL2(forkProvider, fork.forkAtBlockNumber, sourceChain, destinationChain, sender);
   deleteForkById(forkId);

   return simulationResponse;
};