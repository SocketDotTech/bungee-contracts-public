import fs from "fs";
import { ethers } from "hardhat";
import path from "path";

const hre = require("hardhat");
const SOCKET_GATEWAY_KEY = "SocketGateway";

// usage: npx hardhat run script/add-route.ts --network polygon
export const addRoute = async () => {
  try {
    const { getNamedAccounts, network } = hre;
    const { deployer } = await getNamedAccounts();

    const networkName = network.name;

    const networkFilePath = path.join(
      __dirname,
      `../deployments/${networkName}.json`
    );

    let deployment_json = undefined;
    deployment_json = fs.readFileSync(networkFilePath, "utf-8");
    const deployment = JSON.parse(deployment_json);

    const signer = await ethers.getSigner(deployer);
    const factory = await ethers.getContractFactory("SocketGateway");
    const socketGatewayAddress = deployment?.[SOCKET_GATEWAY_KEY];
    const socketGateway = factory.attach(socketGatewayAddress);

    // Add the route address here.
    const tx = await socketGateway.connect(signer).addRoute("");
    await tx.wait();
    console.log(tx);
    return {
      success: true,
    };
  } catch (error) {
    console.log("error in adding routes to the Socketgateway", error);
    return {
      success: false,
    };
  }
};

addRoute()
  .then(() => {
    console.log("done");
    process.exit(0);
  })
  .catch((e) => {
    console.error("failed", e);
    process.exit(1);
  });
