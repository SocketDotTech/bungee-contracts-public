
import { ethers, run } from 'hardhat';
import { create3Factory } from './config';
import Create3Abi from '../../abi/create3/Create3Factory.json';
const hre = require("hardhat");
const CONTRACT_NAME = "Added Socket Route";
const socketGateway = "0x3a23F943181408EAC424116Af7b7790c94Cb97a5";
const implAddress = "0x5Cb5A509beD96B2d168DC8aD85736B0b90da8473"
const fs = require('fs');
const path = require('path');
export const deployController = async (socketGateway: string,implAddress: string) => {
  try {
    const { deployments, getNamedAccounts, network} = hre;
    const networkName = network.name;
    const { deployer } = await getNamedAccounts();
    const owner = deployer;

    console.log("deployer ", deployer);
    console.log("owner", owner);
    console.log("socketDeployFactory", socketGateway);
    console.log("implAddress", implAddress);


    const socketGatewayFactory = await ethers.getContractFactory('SocketGateway');
    const socketGatewayContract = await socketGatewayFactory.attach(socketGateway);

    
    // deploy the route
    const routeAddress = await socketGatewayContract.addController(implAddress);
    console.log("routeAddress", routeAddress);


  } catch (error) {
    console.log(`Error in deploying ${CONTRACT_NAME}`, error);
    return {
      success: false,
    };
  }
};

  deployController(socketGateway, implAddress)
  .then(() => {
    console.log(`✅ finished running the deployment of ${CONTRACT_NAME}`);
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

