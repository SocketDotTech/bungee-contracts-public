import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import { config as dotenvConfig } from "dotenv";
import fs from "fs";
import "hardhat-deploy";
import "hardhat-preprocessor";
import { HardhatUserConfig } from "hardhat/config";
import { resolve } from "path";

dotenvConfig({ path: resolve(__dirname, "./.env") });

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line) => line.trim().split("="));
}

const getEtherscanKey = () => {
  let network;
  for (let i = 0; i < process.argv.length; i++) {
    if (process.argv[i] === "--network") {
      network = process.argv[i + 1];
      break;
    }
  }

  if (!network) {
    return "";
  }

  switch (network) {
    case "mainnet":
      return process.env.MAINNET_ETHERSCAN_KEY;
    case "polygon":
      return process.env.POLYGON_ETHERSCAN_KEY;
    case "opt":
      return process.env.OPTIMISM_ETHERSCAN_KEY;
    case "arbitrum":
      return process.env.ARBITRUM_ETHERSCAN_KEY;
    case "avalanche":
      return process.env.AVALANCHE_ETHERSCAN_KEY;
    case "bsc":
      return process.env.BINANCE_ETHERSCAN_KEY;
    case "fantom":
      return process.env.FANTOM_ETHERSCAN_KEY;
    case "aurora":
      return process.env.AURORA_ETHERSCAN_KEY;
    case "xdai":
      return process.env.GNOSIS_ETHERSCAN_KEY;
    case "polygonZKevm":
      return process.env.POLYGON_ZKEVM_ETHERSCAN_KEY;
    case "scroll":
      return process.env.SCROLL_ETHERSCAN_KEY;
    default:
      return "";
  }
};

// const mnemonic = process.env.SOCKET_MNEMONIC;
// if (!mnemonic) {
//   throw new Error("Please set your SOCKET_MNEMONIC in a .env file");
// }

const socketDeployerKey = process.env.SOCKET_DEPLOYER_KEY;
if (!socketDeployerKey) {
  throw new Error("Please set your SOCKET_DEPLOYER_KEY in a .env file");
}
const ethereumRPC = process.env.ETHEREUM_RPC;
if (!ethereumRPC) {
  throw new Error("Please set your ETHEREUM_RPC in a .env file");
}

const XDAI_RPC = process.env.XDAI_RPC;
if (!XDAI_RPC) {
  throw new Error("Please set your XDAI_RPC in a .env file");
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
    },
  },
  networks: {
    // hardhat: {
    //   accounts: [socketDeployerKey],
    //   chainId: 31337,
    //   forking: {
    //     url: `${ethereumRPC}`,
    //     blockNumber: 13770153,
    //   },
    // },
    mainnet: {
      url: `${ethereumRPC}`,
      gasPrice: 18_000_000_000, // 30 gwei
      gasMultiplier: 1.5,
      chainId: 1,
      accounts: [socketDeployerKey],
    },
    xdai: {
      url: XDAI_RPC,
      gasPrice: 5_000_000_000, // 5 gwei
      gasMultiplier: 1.5,
      chainId: 100,
      accounts: [socketDeployerKey],
    },
    polygon: {
      url: process.env.POLYGON_RPC,
      gasPrice: 150_000_000_000, // 40 gwei
      gasMultiplier: 1.5,
      chainId: 137,
      accounts: [socketDeployerKey],
    },
    bsc: {
      url: `https://bsc-dataseed.binance.org/`,
      gasPrice: 5_000_000_000, // 5 gwei
      gasMultiplier: 1.5,
      chainId: 56,
      accounts: [socketDeployerKey],
    },
    fantom: {
      url: `https://rpc.ftm.tools/`,
      // gasPrice: 5_000_000_000, // 5 gwei
      gasMultiplier: 1.5,
      chainId: 250,
      accounts: [socketDeployerKey],
    },
    avalanche: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      // gasPrice: 5_000_000_000, // 5 gwei
      gasMultiplier: 1.5,
      chainId: 43114,
      accounts: [socketDeployerKey],
    },
    opt: {
      url: `https://mainnet.optimism.io`,
      // gasPrice: 5_000_000_000, // 5 gwei
      gasMultiplier: 1.5,
      chainId: 10,
      accounts: [socketDeployerKey],
    },
    arbitrum: {
      url: `https://arb1.arbitrum.io/rpc`,
      // gasPrice: 5_000_000_000, // 5 gwei
      gasMultiplier: 1.5,
      chainId: 42161,
      accounts: [socketDeployerKey],
    },
    aurora: {
      url: "https://mainnet.aurora.dev",
      chainId: 1313161554,
      accounts: [socketDeployerKey],
    },
    polygonZKevm: {
      url: "https://rpc.ankr.com/polygon_zkevm",
      // gasPrice: 7_000_000_000,
      chainId: 1101,
      accounts: [socketDeployerKey],
    },
    base: {
      url: process.env.BASE_RPC,
      // gasPrice: 7_000_000_000,
      chainId: 8453,
      accounts: [socketDeployerKey],
    },
    linea: {
      url: process.env.LINEA_RPC,
      // gasPrice: 3_900_000_000,
      chainId: 59144,
      accounts: [socketDeployerKey],
    },
    mantle: {
      url: process.env.MANTLE_RPC,
      // gasPrice: 3_900_000_000,
      chainId: 5000,
      accounts: [socketDeployerKey],
    },
    scroll: {
      url: process.env.SCROLL_RPC,
      // gasPrice: 4_000_000_000,
      chainId: 534352,
      accounts: [socketDeployerKey],
    },
    blast: {
      url: process.env.BLAST_RPC,
      // gasPrice: 3_900_000_000,
      chainId: 81457,
      accounts: [socketDeployerKey],
    },
  },
  etherscan: {
    // apiKey: getEtherscanKey(),
    apiKey: {
      polygon: process.env.POLYGON_ETHERSCAN_KEY,
      gnosis: process.env.GNOSIS_ETHERSCAN_KEY,
      optimisticEthereum: process.env.OPTIMISM_ETHERSCAN_KEY,
      arbitrumOne: process.env.ARBITRUM_ETHERSCAN_KEY,
      aurora: process.env.AURORA_ETHERSCAN_KEY,
      bsc: process.env.BINANCE_ETHERSCAN_KEY,
      opera: process.env.FANTOM_ETHERSCAN_KEY,
      avalanche: process.env.AVALANCHE_ETHERSCAN_KEY,
      mainnet: process.env.MAINNET_ETHERSCAN_KEY,
      polygonZKevm: process.env.POLYGON_ZKEVM_ETHERSCAN_KEY,
      base: process.env.BASE_ETHERSCAN_KEY,
      linea: process.env.LINEA_ETHERSCAN_KEY,
      mantle: process.env.MAINNET_ETHERSCAN_KEY,
      scroll: process.env.SCROLL_ETHERSCAN_KEY,
      blast: process.env.BLAST_ETHERSCAN_KEY,
    },
    customChains: [
      {
        network: "polygonZKevm",
        chainId: 1101,
        urls: {
          browserURL: "https://zkevm.polygonscan.com",
          apiURL: "https://api-zkevm.polygonscan.com/api",
        },
      },
      {
        network: "base",
        chainId: 8453,
        urls: {
          browserURL: "https://basescan.org/",
          apiURL: "https://api.basescan.org/api",
        },
      },
      {
        network: "linea",
        chainId: 59144,
        urls: {
          browserURL: "https://lineascan.build/",
          apiURL: "https://api.lineascan.build/api",
        },
      },
      {
        network: "mantle",
        chainId: 5000,
        urls: {
          apiURL: "https://explorer.mantle.xyz/api",
          browserURL: "https://explorer.mantle.xyz",
        },
      },
      {
        network: "scroll",
        chainId: 534352,
        urls: {
          apiURL: "https://api.scrollscan.com/api",
          browserURL: "https://scrollscan.com",
        },
      },
      {
        network: "blast",
        chainId: 81457,
        urls: {
          apiURL: "https://api.blastscan.io/api",
          browserURL: "https://blastscan.io",
        },
      },
    ],
  },
  paths: {
    sources: "./src", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
};

export default config;
