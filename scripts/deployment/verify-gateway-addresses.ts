
import { ethers } from 'hardhat';
const hre = require("hardhat");
const SOCKET_GATEWAY_KEY = "SocketGateway";
const SOCKET_DEPLOY_FACTORY_KEY = "SocketDeployFactory";
const fs = require('fs');
const path = require('path');
export const deploySocketGateway = async () => {
  try {
    const { deployments, getNamedAccounts, network} = hre;
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
    deployment_json = fs.readFileSync(networkFilePath, "utf-8");
    const deployment = JSON.parse(deployment_json);
    if(!deployment?.[SOCKET_DEPLOY_FACTORY_KEY]) throw new Error("SOCKET DEPLOY FACTORY not deployed");

    const socketDeployFactory = deployment?.[SOCKET_DEPLOY_FACTORY_KEY];

    if(!deployment?.[SOCKET_DEPLOY_FACTORY_KEY]) throw new Error("SOCKET DEPLOY FACTORY not deployed");

    const socketGateway = deployment?.[SOCKET_GATEWAY_KEY];
    if(!socketGateway) throw new Error("SOCKET GATEWAY not deployed");


    console.log("socketDeployFactory", socketDeployFactory)

    const SocketDeployFactory = await ethers.getContractFactory('SocketDeployFactory');
    const socketDeployFactoryContract = await SocketDeployFactory.attach(socketDeployFactory);
    console.log("socketDeployFactoryContract", socketDeployFactoryContract.address);
    let routeIdMap: any = {};
    for(let i = 1; i < 385; i++) {
      let routeAddress = await socketDeployFactoryContract.getContractAddress(i);
      routeIdMap[i] = routeAddress;
    }

    const SocketGateway = await ethers.getContractFactory('SocketGateway');
    const socketGatewayContract = await SocketGateway.attach(socketGateway);
    console.log("socketGatewayContract", socketGatewayContract.address);
    let routeIdMap2: any = {};
    for(let i = 1; i < 385; i++) {
        let routeAddress = await socketGatewayContract.addressAt(i);
        routeIdMap2[i] = routeAddress;
    }

    for(let i = 1; i < 385; i++) {
        if(routeIdMap[i] !== routeIdMap2[i]) throw new Error("🥲 routeIdMap and routeIdMap2 not equal");
    }

    console.log('✅ Verified all address are same at gateway and deploy factory')

} catch(err) {
    console.log("err", err);
    return {
      success: false,
      address: undefined,
    };
  }
}


  deploySocketGateway()
  .then(() => {
    console.log(`✅ Verification complete you can breathe now!`);
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

