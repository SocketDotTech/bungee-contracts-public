export enum ChainCodes {
    ETH,
    POLYGON,
    ARBITRUM,
    OPTIMISM,
    BSC
}

export const ETH_CHAIN_ID = 1;
export const POLYGON_CHAIN_ID = 137;
export const ARBITRUM_CHAIN_ID = 42161;
export const OPTIMISM_CHAIN_ID = 10;
export const BSC_CHAIN_ID = 56;

export const ChainCodeToChainId = new Map([
    [ChainCodes.ETH, ETH_CHAIN_ID],
    [ChainCodes.POLYGON, POLYGON_CHAIN_ID],
    [ChainCodes.ARBITRUM, ARBITRUM_CHAIN_ID],
    [ChainCodes.OPTIMISM, OPTIMISM_CHAIN_ID],
    [ChainCodes.BSC, BSC_CHAIN_ID]
]);

export enum TokenCodes {
    USDC,
    DAI,
    NATIVE_TOKEN
}

export const NATIVE_TOKEN_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

export const Tokens = new Map([
    [TokenCodes.USDC,
        new Map([
            [ChainCodes.ETH, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"],
            [ChainCodes.POLYGON, "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"],
            [ChainCodes.ARBITRUM, "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"],
            [ChainCodes.OPTIMISM, "0x7F5c764cBc14f9669B88837ca1490cCa17c31607"],
            [ChainCodes.BSC, "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"],
        ])],
    [TokenCodes.DAI,
        new Map([
            [ChainCodes.ETH, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"],
            [ChainCodes.POLYGON, "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"],
            [ChainCodes.ARBITRUM, "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1"],
            [ChainCodes.OPTIMISM, "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1"],
            [ChainCodes.BSC, "0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3"],
        ])],
    [TokenCodes.NATIVE_TOKEN,
        new Map([
            [ChainCodes.ETH, NATIVE_TOKEN_ADDRESS],
            [ChainCodes.POLYGON, NATIVE_TOKEN_ADDRESS],
            [ChainCodes.ARBITRUM, NATIVE_TOKEN_ADDRESS],
            [ChainCodes.OPTIMISM, NATIVE_TOKEN_ADDRESS],
            [ChainCodes.BSC, NATIVE_TOKEN_ADDRESS],
        ])],   
]);

export const Eth_Whale = '0x0a4c79cE84202b03e95B7a692E5D728d83C44c76';
export const Polygon_Whale = '0xC882b111A75C0c657fC507C04FbFcD2cC984F071';
export const Optimism_Whale = '0xF977814e90dA44bFA03b6295A0616a897441aceC';
export const Arbitrum_Whale = '0xF977814e90dA44bFA03b6295A0616a897441aceC';

export const Whales = new Map([
    [ChainCodes.ETH, Eth_Whale],
    [ChainCodes.POLYGON, Polygon_Whale],
    [ChainCodes.ARBITRUM, Arbitrum_Whale],
    [ChainCodes.OPTIMISM, Optimism_Whale],
]);

export enum BridgeType {
    BRIDGE,
    DIRECT_BRIDGE
}

export enum TokenType {
    ERC20,
    NATIVE
}

export enum BridgeCodes {
    ACROSS,
    ANYSWAP_V4_L1,
    ANYSWAP_V4_L2,
    CBRIDGE,
    HOP_L1,
    HOP_L2,
    HYPHEN,
    NATIVE_OPTIMISM,
    NATIVE_ARBITRUM,
    NATIVE_POLYGON,
    STARGATE_L1,
    STARGATE_L2,
    REFUEL
}

// bridgeCode to bridge-Implementation
export const Bridges = new Map([
    [BridgeCodes.ACROSS, "AcrossImpl"],
    [BridgeCodes.ANYSWAP_V4_L1, "AnyswapImplL1"],
    [BridgeCodes.ANYSWAP_V4_L2, "AnyswapL2Impl"],
    [BridgeCodes.CBRIDGE, "CelerImpl"],
    [BridgeCodes.HOP_L1, "HopImplL1"],
    [BridgeCodes.HOP_L2, "HopImplL2"],
    [BridgeCodes.HYPHEN, "HyphenImpl"],
    [BridgeCodes.NATIVE_OPTIMISM, "NativeOptimismImpl"],
    [BridgeCodes.NATIVE_ARBITRUM, "NativeArbitrumImpl"],
    [BridgeCodes.NATIVE_POLYGON, "NativePolygonImpl"],
    [BridgeCodes.STARGATE_L1, "StargateImplL1"],
    [BridgeCodes.STARGATE_L2, "StargateImplL2"],
    [BridgeCodes.REFUEL, "RefuelBridgeImpl"]
]);

export enum MiddlewareCodes {
    ONEINCH,
    ZEROX,
    RAINBOW
}

// middlewareCode to middleware-Implementation
export const Middlewares = new Map([
    [MiddlewareCodes.ONEINCH, "OneInchImpl"],
    [MiddlewareCodes.ZEROX, "ZeroXSwapImpl"],
    [MiddlewareCodes.RAINBOW, "RainbowSwapImpl"]
]);

export type SimulationResponse = {
    bridgeName: string;
    bridgeType: string;
    gasUsed: number;
    isSuccessful: boolean;
    sourceChainCode: string;
    sourceChainId: number;
    destinationChainCode: string;
    destinationChainId: number;
    tokenCode: string;
    tokenType: string;
    tokenAddress: string;
}

export type Fork = {
    chainCode : string;
    networkId : number;
    blockNumber : number; 
}

export type SimulationResponsesWrapper = {
    simulationResponses : SimulationResponse[];
}
