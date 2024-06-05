import Create3Abi from "../../abi/create3/Create3Factory.json";
import { create3Factory } from "./config";
import fs from "fs";
import { ethers, run } from "hardhat";
import path from "path";

const hre = require("hardhat");

const CONTRACT_NAME = "DisabledSocketRoute";
export const deploySocketDisableRoute = async () => {
  try {
    const { deployments, getNamedAccounts, network } = hre;
    const networkName = network.name;
    const { deployer } = await getNamedAccounts();
    const owner = deployer;

    console.log("deployer ", deployer);
    console.log("owner", owner);

    const networkFilePath = path.join(
      __dirname,
      `../../deployments/${networkName}.json`
    );
    // check if the contract is already deployed in deployments folder in json
    let deployment_json = undefined;
    try {
      deployment_json = fs.readFileSync(networkFilePath, "utf-8");
      if (deployment_json) {
        const deployment = JSON.parse(deployment_json);
        if (deployment?.[CONTRACT_NAME]) {
          console.log(
            "socketDisableRoute already deployed at ",
            deployment?.[CONTRACT_NAME]
          );
          return {
            success: true,
            address: deployment?.[CONTRACT_NAME],
          };
        }
      }
    } catch (error) {
      console.log("Network file doesn't exists creating a new file for ", networkName);
    }

    const factory = await ethers.getContractFactory(CONTRACT_NAME);

    // get signer for the deployer
    const deployerSigner = await ethers.provider.getSigner(deployer);

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
      ethers.utils.defaultAbiCoder.encode(["address"], [owner]).slice(2);
    // find salt for the contract
    const salt = ethers.utils.formatBytes32String(CONTRACT_NAME);

    const tx = await create3FactoryContract.deploy(salt, creationCodeWithArgs);
    const receipt = await tx.wait();
    const deployedAddress = await create3FactoryContract.getDeployed(
      owner,
      salt
    );
    console.log("deployedAddress", deployedAddress);
    const socketDisableRoute = await ethers.getContractAt(
      CONTRACT_NAME,
      deployedAddress
    );

    // save the contract address in deployments folder in json
    if (!deployment_json) {
      const data = {
        [CONTRACT_NAME]: socketDisableRoute.address,
      };
      // create a new file for the network
      
      fs.writeFileSync(
        networkFilePath,
        JSON.stringify(data, null, 2),
        "utf-8"
      );

    } else {
      const deployment = JSON.parse(deployment_json);
      deployment[CONTRACT_NAME] = socketDisableRoute.address;
      fs.writeFileSync(
        networkFilePath,
        JSON.stringify(deployment, null, 2),
        "utf-8"
      );
    }

    console.log("socketDisableRoute deployed to:", socketDisableRoute.address);

      // verify 
      await run("verify:verify", {
        address: socketDisableRoute.address,
        constructorArguments: [owner],
      });
        
    return {
      success: true,
      address: socketDisableRoute.address,
    };
  } catch (error) {
    console.log("Error in deploying socketDisableRoute", error);
    return {
      success: false,
    };
  }
};

deploySocketDisableRoute()
  .then(() => {
    console.log("✅ finished running the deployment of socketDisableRoute.");
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
