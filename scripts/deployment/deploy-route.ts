
import { ethers, run } from 'hardhat';
import { create3Factory } from './config';
import Create3Abi from '../../abi/create3/Create3Factory.json';
const hre = require("hardhat");
const CONTRACT_NAME = "Added Socket Route";
const socket_deploy_factory = "0x71630095e3F08A86aFC73f7b07342192adf39C55";
const routeId = 17;
const implAddress = "0xe60F1B805c4bED6703dA1C2fe5d11dEFeA0a9b65"
const fs = require('fs');
const path = require('path');
export const deployRoute = async (socketDeployFactory: string, routeId: number, implAddress: string) => {
  try {
    const { deployments, getNamedAccounts, network} = hre;
    const networkName = network.name;
    const { deployer } = await getNamedAccounts();
    const owner = deployer;

    console.log("deployer ", deployer);
    console.log("owner", owner);
    console.log("socketDeployFactory", socketDeployFactory);
    console.log("routeId", routeId);
    console.log("implAddress", implAddress);


    const SocketDeployFactory = await ethers.getContractFactory('SocketDeployFactory');
    const socketDeployFactoryContract = await SocketDeployFactory.attach(socketDeployFactory);

    
    // deploy the route
    const routeAddress = await socketDeployFactoryContract.deploy(routeId, implAddress);
    console.log("routeAddress", routeAddress);


  } catch (error) {
    console.log(`Error in deploying ${CONTRACT_NAME}`, error);
    return {
      success: false,
    };
  }
};

  deployRoute(socket_deploy_factory, routeId, implAddress)
  .then(() => {
    console.log(`✅ finished running the deployment of ${CONTRACT_NAME}`);
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

