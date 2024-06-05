import { bridgeConfig } from "./config";
import fs from "fs";
import { ethers, run } from "hardhat";
import path from "path";

const hre = require("hardhat");
const CONTRACT_NAME = "CelerV2Impl";
const CELER_STORAGE_WRAPPER = "CelerStorageWrapper";

const SOCKET_DEPLOY_FACTORY_KEY = "SocketDeployFactory";
const SOCKET_GATEWAY_KEY = "SocketGateway";

// const celerStorageWrapper = {
//   1: '0x1768C1D2900f1408D44FbB1EdCc306F94aF852ae',
//   10: '0x7c6C373190421988fA31E64f369C45205676C1f0',
//   56: '0x2d0EeB574cC98f6d57c72FFe730D5C8a8f2eac37',
//   137: '0x7c6C373190421988fA31E64f369C45205676C1f0',
//   250: '0x5CddbecAF8603E5e0bC771A46D48e148593351eA',
//   43114: '0x7c6C373190421988fA31E64f369C45205676C1f0',
//   42161: '0x1768C1D2900f1408D44FbB1EdCc306F94aF852ae',
//   1313161554 :'0x2d0EeB574cC98f6d57c72FFe730D5C8a8f2eac37'
// }

export const deployBridge = async () => {
  try {
    const { deployments, getNamedAccounts, network } = hre;
    const { deployer } = await getNamedAccounts();
    const owner = deployer;
    const networkName = network.name;
    const celerRouterAddress = bridgeConfig[networkName].celerRouterAddress;
    const wethAddress = bridgeConfig[networkName].wethAddress;

    if (!celerRouterAddress || !wethAddress)
      throw new Error("CelerRouter or WETH address not found in config file");

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

    // if (deployment?.[CONTRACT_NAME]) {
    //   console.log("CelerImpl already deployed at ", deployment?.[CONTRACT_NAME]);
    //   return {
    //     success: true,
    //     address: deployment?.[CONTRACT_NAME],
    //   };
    // }

    console.log("deployer ", deployer);
    console.log("owner", owner);
    console.log("socketGateway", socketGateway);
    console.log("socketDeployFactory", socketDeployFactory);
    console.log("celer storage wrapper", deployment?.CelerStorageWrapper);

    const celerStorageFactory = await ethers.getContractFactory(
      CELER_STORAGE_WRAPPER
    );
    const celerStorageFactoryContract = await celerStorageFactory.deploy(
      socketGateway
    );
    console.log(`about to deploy ${CELER_STORAGE_WRAPPER}`);
    await celerStorageFactoryContract.deployed();
    console.log(
      `${CELER_STORAGE_WRAPPER} deployed to:`,
      celerStorageFactoryContract.address
    );

    const factory = await ethers.getContractFactory(CONTRACT_NAME);
    const Contract = await factory.deploy(
      celerRouterAddress,
      wethAddress,
      // celerStorageFactoryContract.address,
      deployment?.CelerStorageWrapper,
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
      // [CELER_STORAGE_WRAPPER]: celerStorageFactoryContract.address,
      [CELER_STORAGE_WRAPPER]: deployment?.CelerStorageWrapper,
    };

    fs.writeFileSync(
      networkFilePath,
      JSON.stringify(newDeployment, null, 2),
      "utf-8"
    );

    // verify the contract on etherscan
    await run("verify:verify", {
      address: Contract.address,
      // address: "0x9c9ce42eadd82457fb72f8361a0532e48e93147c",
      constructorArguments: [
        celerRouterAddress,
        wethAddress,
        // celerStorageFactoryContract.address,
        deployment?.CelerStorageWrapper,
        socketGateway,
        socketDeployFactory,
      ],
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
