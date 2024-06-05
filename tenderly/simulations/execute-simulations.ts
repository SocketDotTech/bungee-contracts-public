import {SimulationResponsesWrapper, ChainCodes, SimulationResponse, Eth_Whale, Polygon_Whale, Arbitrum_Whale, Optimism_Whale} from "../../static-data/ll-static-data";

import {executeAcrossERC20Bridge} from "./executions/bridges/across/erc20/run-across-erc20-bridge";
import { executeAcrossERC20DirectBridge } from "./executions/bridges/across/erc20/run-across-erc20-direct-bridge";
import { executeAcrossNativeBridge } from "./executions/bridges/across/native/run-across-native-bridge";
import { executeAcrossNativeDirectBridge } from "./executions/bridges/across/native/run-across-native-direct-bridge";

import {executeAnyswapL1ERC20Bridge} from "./executions/bridges/anyswap/l1/erc20/run-anyswap-l1-erc20-bridge";
import {executeAnyswapL1ERC20DirectBridge} from "./executions/bridges/anyswap/l1/erc20/run-anyswap-l1-erc20-direct-bridge";

import {executeCBridgeERC20Bridge} from "./executions/bridges/cbridge/erc20/run-cbridge-erc20-bridge";
import {executeCBridgeERC20DirectBridge} from "./executions/bridges/cbridge/erc20/run-cbridge-erc20-direct-bridge";
import {executeCBridgeNativeBridge} from "./executions/bridges/cbridge/native/run-cbridge-native-bridge";
import {executeCBridgeNativeDirectBridge} from "./executions/bridges/cbridge/native/run-cbridge-native-direct-bridge";

import {executeHopL1ERC20Bridge} from "./executions/bridges/hop/l1/erc20/run-hop-l1-erc20-bridge";
import {executeHopL1ERC20DirectBridge} from "./executions/bridges/hop/l1/erc20/run-hop-l1-erc20-direct-bridge";
import {executeHopL1NativeBridge} from "./executions/bridges/hop/l1/native/run-hop-l1-native-bridge";
import {executeHopL1NativeDirectBridge} from "./executions/bridges/hop/l1/native/run-hop-l1-native-direct-bridge";

import {executeHyphenERC20Bridge} from "./executions/bridges/hyphen/erc20/run-hyphen-erc20-bridge";
import {executeHyphenERC20DirectBridge} from "./executions/bridges/hyphen/erc20/run-hyphen-erc20-direct-bridge";
import {executeHyphenNativeBridge} from "./executions/bridges/hyphen/native/run-hyphen-native-bridge";
import {executeHyphenNativeDirectBridge} from "./executions/bridges/hyphen/native/run-hyphen-native-direct-bridge";

import {executeNativeArbitrumERC20Bridge} from "./executions/bridges/native-arbitrum/run-native-arbitrum-erc20-bridge";
import {executeNativeArbitrumERC20DirectBridge} from "./executions/bridges/native-arbitrum/run-native-arbitrum-erc20-direct-bridge";

import {executeNativeOptimismERC20Bridge} from "./executions/bridges/native-optimism/run-native-optimism-erc20-bridge";
import {executeNativeOptimismERC20DirectBridge} from "./executions/bridges/native-optimism/run-native-optimism-erc20-direct-bridge";

import {executeNativePolygonERC20Bridge} from "./executions/bridges/native-polygon/run-native-polygon-erc20-bridge";
import {executeNativePolygonERC20DirectBridge} from "./executions/bridges/native-polygon/run-native-polygon-erc20-direct-bridge";

import {executeStargateL1ERC20Bridge} from "./executions/bridges/stargate/l1/erc20/run-stargate-l1-erc20-bridge";
import {executeStargateL1ERC20DirectBridge} from "./executions/bridges/stargate/l1/erc20/run-stargate-l1-erc20-direct-bridge";
import {executeStargateL1NativeBridge} from "./executions/bridges/stargate/l1/native/run-stargate-l1-native-bridge";
import {executeStargateL1NativeDirectBridge} from "./executions/bridges/stargate/l1/native/run-stargate-l1-native-direct-bridge";

import {executeAnyswapL2ERC20Bridge} from "./executions/bridges/anyswap/l2/erc20/run-anyswap-l2-erc20-bridge";
import {executeAnyswapL2ERC20DirectBridge} from "./executions/bridges/anyswap/l2/erc20/run-anyswap-l2-erc20-direct-bridge";

import {executeHopL2ERC20Bridge} from "./executions/bridges/hop/l2/erc20/run-hop-l2-erc20-bridge";
import {executeHopL2ERC20DirectBridge} from "./executions/bridges/hop/l2/erc20/run-hop-l2-erc20-direct-bridge";
import {executeHopL2NativeBridge} from "./executions/bridges/hop/l2/native/run-hop-l2-native-bridge";
import {executeHopL2NativeDirectBridge} from "./executions/bridges/hop/l2/native/run-hop-l2-native-direct-bridge";

import {executeStargateL2ERC20Bridge} from "./executions/bridges/stargate/l2/erc20/run-stargate-l2-erc20-bridge";
import {executeStargateL2ERC20DirectBridge} from "./executions/bridges/stargate/l2/erc20/run-stargate-l2-erc20-direct-bridge";
import {executeStargateL2NativeBridge} from "./executions/bridges/stargate/l2/native/run-stargate-l2-native-bridge";
import {executeStargateL2NativeDirectBridge} from "./executions/bridges/stargate/l2/native/run-stargate-l2-native-direct-bridge";

// npx ts-node tenderly/commands/command-run-all-simulations.ts
export const executeSimulations = async () => {

   let simulationResponses : SimulationResponse[] = [];

   //L1 Simulations

   // //Across
   // const simulationResponse_BridgeERC20OnAcross = await executeAcrossERC20Bridge(ChainCodes.ETH, ChainCodes.OPTIMISM, 0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnAcross);

   // const simulationResponse_DirectBridgeERC20OnAcross = await executeAcrossERC20DirectBridge(ChainCodes.ETH, ChainCodes.OPTIMISM, 0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeERC20OnAcross);

   // const simulationResponse_BridgeNativeOnAcross = await executeAcrossNativeBridge(ChainCodes.ETH, ChainCodes.OPTIMISM, 0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnAcross);

   // const simulationResponse_DirectBridgeNativeOnAcross = await executeAcrossNativeDirectBridge(ChainCodes.ETH, ChainCodes.OPTIMISM, 0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeNativeOnAcross);

   // //Anyswap
   // const simulationResponse_BridgeERC20OnAnySwap_l1 = await executeAnyswapL1ERC20Bridge(ChainCodes.ETH, ChainCodes.ARBITRUM, 0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnAnySwap_l1);

   // const simulationResponse_Direct_BridgeERC20OnAnySwap_l1 = await executeAnyswapL1ERC20DirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM, 0, Eth_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeERC20OnAnySwap_l1);

   // //CBridge

   // const simulationResponse_BridgeERC20OnCBridge_l1 = await executeCBridgeERC20Bridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnCBridge_l1);

   // const simulationResponse_Direct_BridgeERC20OnCBridge_l1 = await executeCBridgeERC20DirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeERC20OnCBridge_l1);

   // const simulationResponse_BridgeNativeOnCBridge_l1 = await executeCBridgeNativeBridge(ChainCodes.ETH, ChainCodes.ARBITRUM, 0,  Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnCBridge_l1);

   // const simulationResponse_Direct_BridgeNativeOnCBridge_l1 = await executeCBridgeNativeDirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeNativeOnCBridge_l1);

   // //Hop
   const simulationResponse_BridgeERC20OnHopL1 = await executeHopL1ERC20Bridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   simulationResponses.push(simulationResponse_BridgeERC20OnHopL1);

   // const simulationResponse_DirectBridgeERC20OnHopL1 = await executeHopL1ERC20DirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeERC20OnHopL1);

   // const simulationResponse_BridgeNativeOnHopL1 = await executeHopL1NativeBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnHopL1);

   // const simulationResponse_DirectBridgeNativeOnHopL1 = await executeHopL1NativeDirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeNativeOnHopL1);

   // //Hyphen
   // const simulationResponse_BridgeERC20OnHyphen_l1 = await executeHyphenERC20Bridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnHyphen_l1);

   // const simulationResponse_Direct_BridgeERC20OnHyphen_l1 = await executeHyphenERC20DirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeERC20OnHyphen_l1);

   // const simulationResponse_BridgeNativeOnHyphen_l1 = await executeHyphenNativeBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnHyphen_l1);

   // const simulationResponse_Direct_BridgeNativeOnHyphen_l1 = await executeHyphenNativeDirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeNativeOnHyphen_l1);

   // //Native-Arbitrum
   // const simulationResponse_BridgeERC20OnNativeArbitrum = await executeNativeArbitrumERC20Bridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnNativeArbitrum);

   // const simulationResponse_DirectBridgeERC20OnNativeArbitrum = await executeNativeArbitrumERC20DirectBridge(ChainCodes.ETH, ChainCodes.ARBITRUM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeERC20OnNativeArbitrum);

   // //Native-Optimism
   // const simulationResponse_BridgeERC20OnNativeOptimism = await executeNativeOptimismERC20Bridge(ChainCodes.ETH, ChainCodes.OPTIMISM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnNativeOptimism);

   // const simulationResponse_DirectBridgeERC20OnNativeOptimism = await executeNativeOptimismERC20DirectBridge(ChainCodes.ETH, ChainCodes.OPTIMISM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeERC20OnNativeOptimism);

   // //Native-Polygon
   // const simulationResponse_BridgeERC20OnNativepolygon = await executeNativePolygonERC20Bridge(ChainCodes.ETH, ChainCodes.POLYGON,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnNativepolygon);

   // const simulationResponse_DirectBridgeERC20OnNativepolygon = await executeNativePolygonERC20DirectBridge(ChainCodes.ETH, ChainCodes.POLYGON,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeERC20OnNativepolygon);

   // //Stargate
   // const simulationResponse_BridgeERC20OnStargate_l1 = await executeStargateL1ERC20Bridge(ChainCodes.ETH, ChainCodes.OPTIMISM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnStargate_l1);

   // const simulationResponse_Direct_BridgeERC20OnStargate_l1 = await executeStargateL1ERC20DirectBridge(ChainCodes.ETH, ChainCodes.OPTIMISM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeERC20OnStargate_l1);

   // const simulationResponse_BridgeNativeOnStargate_l1 = await executeStargateL1NativeBridge(ChainCodes.ETH, ChainCodes.OPTIMISM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnStargate_l1);

   // const simulationResponse_DirectBridgeNativeOnStargate_l1 = await executeStargateL1NativeDirectBridge(ChainCodes.ETH, ChainCodes.OPTIMISM,  0, Eth_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeNativeOnStargate_l1);   

   // //L2 Simulations

   // //Anyswap
   // const simulationResponse_BridgeERC20OnAnySwap_l2 = await executeAnyswapL2ERC20Bridge(ChainCodes.POLYGON, ChainCodes.OPTIMISM,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnAnySwap_l2);

   // const simulationResponse_Direct_BridgeERC20OnAnySwap_l2 = await executeAnyswapL2ERC20DirectBridge(ChainCodes.POLYGON, ChainCodes.OPTIMISM,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeERC20OnAnySwap_l2);

   // //HopL2
   // const simulationResponse_BridgeERC20OnHopL2 = await executeHopL2ERC20Bridge(ChainCodes.POLYGON, ChainCodes.OPTIMISM,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnHopL2);

   // const simulationResponse_DirectBridgeERC20OnHopL2 = await executeHopL2ERC20DirectBridge(ChainCodes.POLYGON, ChainCodes.OPTIMISM,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnHopL2);

   // const simulationResponse_BridgeNativeOnHopL2 = await executeHopL2NativeBridge(ChainCodes.POLYGON, ChainCodes.ETH,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnHopL2);

   // const simulationResponse_DirectBridgeNativeOnHopL2 = await executeHopL2NativeDirectBridge(ChainCodes.POLYGON, ChainCodes.ETH,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeNativeOnHopL2);

   // //Stargate
   // const simulationResponse_BridgeERC20OnStargate_l2 = await executeStargateL2ERC20Bridge(ChainCodes.POLYGON, ChainCodes.OPTIMISM,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_BridgeERC20OnStargate_l2);

   // const simulationResponse_Direct_BridgeERC20OnStargate_l2 = await executeStargateL2ERC20DirectBridge(ChainCodes.POLYGON, ChainCodes.OPTIMISM,  0, Polygon_Whale);
   // simulationResponses.push(simulationResponse_Direct_BridgeERC20OnStargate_l2);

   // const simulationResponse_BridgeNativeOnStargate_l2 = await executeStargateL2NativeBridge(ChainCodes.OPTIMISM, ChainCodes.ARBITRUM,  0, Optimism_Whale);
   // simulationResponses.push(simulationResponse_BridgeNativeOnStargate_l2);

   // const simulationResponse_DirectBridgeNativeOnStargate_l2 = await executeStargateL2NativeDirectBridge(ChainCodes.OPTIMISM, ChainCodes.ARBITRUM,  0, Optimism_Whale);
   // simulationResponses.push(simulationResponse_DirectBridgeNativeOnStargate_l2);

   let simulationResponsesWrapper : SimulationResponsesWrapper = <SimulationResponsesWrapper>(
      {
         simulationResponses: simulationResponses
      });
   
   return simulationResponsesWrapper;
};
