import Create3Abi from "../../abi/create3/Create3Factory.json";
import { create3Factory } from "./config";
import { ethers, run } from "hardhat";

const hre = require("hardhat");
const CONTRACT_NAME = "SocketDeployFactory";
const DISABLED_ROUTE_KEY = "DisabledSocketRoute"

const fs = require("fs");
const path = require("path");
export const deploySocketDeployFactory = async (
) => {
  try {
    const { deployments, getNamedAccounts, network } = hre;
    const { deployer } = await getNamedAccounts();
    const owner = deployer;
    const networkName = network.name;
    console.log("deployer ", deployer);
    console.log("owner", owner);

    const networkFilePath = path.join(
      __dirname,
      `../../deployments/${networkName}.json`
    );
    // check if the contract is already deployed in deployments folder in json
    let deployment_json = undefined;
    deployment_json = fs.readFileSync(networkFilePath, "utf-8");
    const deployment = JSON.parse(deployment_json);
    if(!deployment?.[DISABLED_ROUTE_KEY]) throw new Error("DisabledSocketRoute not deployed");

    const socketDisableRouteAddress = deployment?.[DISABLED_ROUTE_KEY];

    if (deployment?.[CONTRACT_NAME]) {
      console.log(
        "Socket Deploy Factory already deployed at ",
        deployment?.[CONTRACT_NAME]
      );
      return {
        success: true,
        address: deployment?.[CONTRACT_NAME],
      };
    }
  
    console.log("socketDisableRouteAddress", socketDisableRouteAddress)
    // deployer singer
    const deployerSigner = await ethers.provider.getSigner(deployer);

    const factory = await ethers.getContractFactory(CONTRACT_NAME);


    const create3FactoryContract = await new ethers.Contract(
      create3Factory,
      Create3Abi,
      deployerSigner
    );
    // find creation code for the contract
    const creationCode = factory.bytecode;
    // add arguments to the creation code
    const creationCodeWithArgs =
      creationCode +
      ethers.utils.defaultAbiCoder
        .encode(["address", "address"], [owner, socketDisableRouteAddress])
        .slice(2);
    // find salt for the contract
    const salt = ethers.utils.formatBytes32String(CONTRACT_NAME );

    const tx = await create3FactoryContract.deploy(salt, creationCodeWithArgs);
    const receipt = await tx.wait();
    const deployedAddress = await create3FactoryContract.getDeployed(
      owner,
      salt
    );

    deployment[CONTRACT_NAME] = deployedAddress;
    fs.writeFileSync(
      networkFilePath,
      JSON.stringify(deployment, null, 2),
      "utf-8"
    );

    console.log("deployedAddress", deployedAddress);

    console.log(`about to deploy ${CONTRACT_NAME}}`);
    // await Contract.deployed();
    console.log(`${CONTRACT_NAME} deployed to:`, deployedAddress);

          // verify 
          await run("verify:verify", {
            address: deployedAddress,
            constructorArguments: [owner, socketDisableRouteAddress],
          });

    return {
      success: true,
      address: deployedAddress,
    };
  } catch (error) {
    console.log(`Error in deploying ${CONTRACT_NAME}`, error);
    return {
      success: false,
    };
  }
};

deploySocketDeployFactory()
  .then(() => {
    console.log(`✅ finished running the deployment of ${CONTRACT_NAME}`);
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
