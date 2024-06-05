import { bridgeConfig } from "./config";
import fs from "fs";
import { ethers, run } from "hardhat";
import path from "path";

const hre = require("hardhat");
const CONTRACT_NAME = "StargateImplL2V2";

const SOCKET_DEPLOY_FACTORY_KEY = "SocketDeployFactory";
const SOCKET_GATEWAY_KEY = "SocketGateway";

export const deployBridge = async () => {
  try {
    const { deployments, getNamedAccounts, network } = hre;
    const { deployer } = await getNamedAccounts();
    const owner = deployer;
    const networkName = network.name;
    const router = bridgeConfig[networkName].router;
    const ethVault = bridgeConfig[networkName].ethVault;

    if (!router || !ethVault)
      throw new Error("router or ethVault address not found in config file");

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

    console.log({ router, ethVault });
    const factory = await ethers.getContractFactory(CONTRACT_NAME);
    const Contract = await factory.deploy(
      router,
      socketGateway,
      socketDeployFactory
    );
    console.log(`about to deploy ${CONTRACT_NAME}`);
    await Contract.deployed();
    console.log(`${CONTRACT_NAME} deployed to:`, Contract.address);
    console.log(router, socketGateway, socketDeployFactory);

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

    // verify the contract
    await run("verify:verify", {
      address: Contract.address,
      constructorArguments: [router, socketGateway, socketDeployFactory],
    });

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
