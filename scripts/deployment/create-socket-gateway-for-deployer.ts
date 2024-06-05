
import { ethers, run } from 'hardhat';
import { create3Factory } from './config';
import Create3Abi from '../../abi/create3/Create3Factory.json';
const hre = require("hardhat");
const CONTRACT_NAME = "SocketGateway";
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

    if (deployment?.[CONTRACT_NAME]) {
      console.log(
        "Socket Gateway already deployed at ",
        deployment?.[CONTRACT_NAME]
      );
      return {
        success: true,
        address: deployment?.[CONTRACT_NAME],
      };
    }
  
    console.log("socketDeployFactory", socketDeployFactory)

    const SocketDeployFactory = await ethers.getContractFactory('SocketDeployFactory');
    const socketDeployFactoryContract = await SocketDeployFactory.attach(socketDeployFactory);
    console.log("socketDeployFactoryContract", socketDeployFactoryContract.address);
    let routeIdMap: any = {};
    for(let i = 1; i < 385; i++) {
      let routeAddress = await socketDeployFactoryContract.getContractAddress(i);
      routeIdMap[i] = routeAddress;
    }


    // copy and make a copy of SocketGateway.sol 
    // and replace the ith occurrence 0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f with i th address from routeIdMap
    // and then deploy that contract
    // and then return the address of that contract

    const socketGatewayPath = path.join(__dirname, '../../src/SocketGateway.sol');
    const socketGatewayCopyPath = path.join(__dirname, `../../src/SocketGatewayDeployment.sol`);
    fs.copyFileSync(socketGatewayPath, socketGatewayCopyPath);
    const socketGatewayCopy = fs.readFileSync(socketGatewayCopyPath, 'utf8');
    const socketGatewayCopyWithContractName = 
            socketGatewayCopy.replace('contract SocketGatewayTemplate', `contract SocketGateway`)


    let socketGatewayCopyWithContractNameAndAddress  = socketGatewayCopyWithContractName;
            
    for(let i = 1; i < 385; i++) {
         socketGatewayCopyWithContractNameAndAddress = 
         socketGatewayCopyWithContractNameAndAddress.replace(`0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f`, routeIdMap[i]);
    }

    fs.writeFileSync(socketGatewayCopyPath, socketGatewayCopyWithContractNameAndAddress, 'utf8');
    

    console.log("routeIdMap", routeIdMap);
    console.log('Created SocketGatewayDeployment.sol')
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
    console.log(`✅ finished creating the deployment of ${CONTRACT_NAME}`);
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

