import { Arbitrum_Whale, ChainCodes, Eth_Whale, Polygon_Whale } from "../../static-data/ll-static-data";
import {executeAcrossERC20Bridge} from "../simulations/executions/bridges/across/erc20/run-across-erc20-bridge";
import { executeAcrossERC20DirectBridge } from "../simulations/executions/bridges/across/erc20/run-across-erc20-direct-bridge";
import { executeAcrossNativeBridge } from "../simulations/executions/bridges/across/native/run-across-native-bridge";
import { executeAcrossNativeDirectBridge } from "../simulations/executions/bridges/across/native/run-across-native-direct-bridge";

import {executeAnyswapL1ERC20Bridge} from "../simulations/executions/bridges/anyswap/l1/erc20/run-anyswap-l1-erc20-bridge";
import {executeAnyswapL1ERC20DirectBridge} from "../simulations/executions/bridges/anyswap/l1/erc20/run-anyswap-l1-erc20-direct-bridge";

import {executeCBridgeERC20Bridge} from "../simulations/executions/bridges/cbridge/erc20/run-cbridge-erc20-bridge";
import {executeCBridgeERC20DirectBridge} from "../simulations/executions/bridges/cbridge/erc20/run-cbridge-erc20-direct-bridge";
import {executeCBridgeNativeBridge} from "../simulations/executions/bridges/cbridge/native/run-cbridge-native-bridge";
import {executeCBridgeNativeDirectBridge} from "../simulations/executions/bridges/cbridge/native/run-cbridge-native-direct-bridge";

import {executeHopL1ERC20Bridge} from "../simulations/executions/bridges/hop/l1/erc20/run-hop-l1-erc20-bridge";
import {executeHopL1ERC20DirectBridge} from "../simulations/executions/bridges/hop/l1/erc20/run-hop-l1-erc20-direct-bridge";
import {executeHopL1NativeBridge} from "../simulations/executions/bridges/hop/l1/native/run-hop-l1-native-bridge";
import {executeHopL1NativeDirectBridge} from "../simulations/executions/bridges/hop/l1/native/run-hop-l1-native-direct-bridge";

import {executeHyphenERC20Bridge} from "../simulations/executions/bridges/hyphen/erc20/run-hyphen-erc20-bridge";
import {executeHyphenERC20DirectBridge} from "../simulations/executions/bridges/hyphen/erc20/run-hyphen-erc20-direct-bridge";
import {executeHyphenNativeBridge} from "../simulations/executions/bridges/hyphen/native/run-hyphen-native-bridge";
import {executeHyphenNativeDirectBridge} from "../simulations/executions/bridges/hyphen/native/run-hyphen-native-direct-bridge";

import {executeNativeArbitrumERC20Bridge} from "../simulations/executions/bridges/native-arbitrum/run-native-arbitrum-erc20-bridge";
import {executeNativeArbitrumERC20DirectBridge} from "../simulations/executions/bridges/native-arbitrum/run-native-arbitrum-erc20-direct-bridge";

import {executeNativeOptimismERC20Bridge} from "../simulations/executions/bridges/native-optimism/run-native-optimism-erc20-bridge";
import {executeNativeOptimismERC20DirectBridge} from "../simulations/executions/bridges/native-optimism/run-native-optimism-erc20-direct-bridge";

import {executeNativePolygonERC20Bridge} from "../simulations/executions/bridges/native-polygon/run-native-polygon-erc20-bridge";
import {executeNativePolygonERC20DirectBridge} from "../simulations/executions/bridges/native-polygon/run-native-polygon-erc20-direct-bridge";

import {executeStargateL1ERC20Bridge} from "../simulations/executions/bridges/stargate/l1/erc20/run-stargate-l1-erc20-bridge";
import {executeStargateL1ERC20DirectBridge} from "../simulations/executions/bridges/stargate/l1/erc20/run-stargate-l1-erc20-direct-bridge";
import {executeStargateL1NativeBridge} from "../simulations/executions/bridges/stargate/l1/native/run-stargate-l1-native-bridge";
import {executeStargateL1NativeDirectBridge} from "../simulations/executions/bridges/stargate/l1/native/run-stargate-l1-native-direct-bridge";

import {executeAnyswapL2ERC20Bridge} from "../simulations/executions/bridges/anyswap/l2/erc20/run-anyswap-l2-erc20-bridge";
import {executeAnyswapL2ERC20DirectBridge} from "../simulations/executions/bridges/anyswap/l2/erc20/run-anyswap-l2-erc20-direct-bridge";

import {executeHopL2ERC20Bridge} from "../simulations/executions/bridges/hop/l2/erc20/run-hop-l2-erc20-bridge";
import {executeHopL2ERC20DirectBridge} from "../simulations/executions/bridges/hop/l2/erc20/run-hop-l2-erc20-direct-bridge";
import {executeHopL2NativeBridge} from "../simulations/executions/bridges/hop/l2/native/run-hop-l2-native-bridge";
import {executeHopL2NativeDirectBridge} from "../simulations/executions/bridges/hop/l2/native/run-hop-l2-native-direct-bridge";

import {executeStargateL2ERC20Bridge} from "../simulations/executions/bridges/stargate/l2/erc20/run-stargate-l2-erc20-bridge";
import {executeStargateL2ERC20DirectBridge} from "../simulations/executions/bridges/stargate/l2/erc20/run-stargate-l2-erc20-direct-bridge";
import {executeStargateL2NativeBridge} from "../simulations/executions/bridges/stargate/l2/native/run-stargate-l2-native-bridge";
import {executeStargateL2NativeDirectBridge} from "../simulations/executions/bridges/stargate/l2/native/run-stargate-l2-native-direct-bridge";

//usage: npx ts-node tenderly/commands/command-run-a-simulation.ts
(async () => {
   const simulationResponse = await executeHopL2ERC20Bridge(ChainCodes.POLYGON, ChainCodes.ARBITRUM, 0, Polygon_Whale);
   console.log(`[Tenderly-Simulation] simulationResponse \n : ${JSON.stringify(simulationResponse, null, 2)}`);

})().catch((e) => {
   console.error('error: ', e);
});