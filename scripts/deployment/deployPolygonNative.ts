import { bridgeConfig } from "./config";
import fs from "fs";
import { ethers, run } from "hardhat";
import path from "path";

const hre = require("hardhat");
const CONTRACT_NAME = "NativePolygonImpl";

const SOCKET_DEPLOY_FACTORY_KEY = "SocketDeployFactory";
const SOCKET_GATEWAY_KEY = "SocketGateway";

export const deployBridge = async () => {
  try {
    const { deployments, getNamedAccounts, network } = hre;
    const { deployer } = await getNamedAccounts();
    const owner = deployer;
    const networkName = network.name;
    const _rootChainManagerProxy =
      bridgeConfig[networkName].rootChainManagerProxy;
    const _erc20PredicateProxy = bridgeConfig[networkName].erc20PredicateProxy;

    if (!_rootChainManagerProxy || !_erc20PredicateProxy)
      throw new Error(
        "rootChainManagerProxy or erc20PredicateProxy address not found in config file"
      );

    if (networkName !== "mainnet") {
      throw new Error("This script is only for mainnet");
    }
    const networkFilePath = path.join(
      __dirname,
      `../../deployments/${networkName}.json`
    );
    // check if the contract is already deployed in deployments folder in json
    let deployment_json = undefined;
    deployment_json = fs.readFileSync(networkFilePath, "utf-8");
    const deployment = JSON.parse(deployment_json);
    if (!deployment?.[SOCKET_DEPLOY_FACTORY_KEY])
      throw new Error("SOCKET DEPLOY FACTORY not deployed");

    const socketDeployFactory = deployment?.[SOCKET_DEPLOY_FACTORY_KEY];

    const socketGateway = deployment?.[SOCKET_GATEWAY_KEY];
    if (!socketGateway) throw new Error("SocketGateway not deployed");

    if (deployment?.[CONTRACT_NAME]) {
      console.log(
        `${CONTRACT_NAME} already deployed at `,
        deployment?.[CONTRACT_NAME]
      );
      return {
        success: true,
        address: deployment?.[CONTRACT_NAME],
      };
    }

    console.log("deployer ", deployer);
    console.log("owner", owner);
    console.log("socketGateway", socketGateway);
    console.log("socketDeployFactory", socketDeployFactory);

    console.log({ _erc20PredicateProxy, _rootChainManagerProxy });
    const factory = await ethers.getContractFactory(CONTRACT_NAME);
    const Contract = await factory.deploy(
      _rootChainManagerProxy,
      _erc20PredicateProxy,
      socketGateway,
      socketDeployFactory
    );
    console.log(`about to deploy ${CONTRACT_NAME}`);
    await Contract.deployed();
    console.log(`${CONTRACT_NAME} deployed to:`, Contract.address);

    // save the contract address in deployments folder
    const newDeployment = {
      ...deployment,
      [CONTRACT_NAME]: Contract.address,
    };

    fs.writeFileSync(
      networkFilePath,
      JSON.stringify(newDeployment, null, 2),
      "utf-8"
    );

    return {
      success: true,
      address: Contract.address,
    };
  } catch (error) {
    console.log(`Error in deploying ${CONTRACT_NAME}`, error);
    return {
      success: false,
    };
  }
};

deployBridge()
  .then(() => {
    console.log(`✅ finished running the deployment of ${CONTRACT_NAME}`);
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
