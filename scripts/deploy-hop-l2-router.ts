import { ethers, run } from "hardhat";
const hre = require("hardhat");
import { addresses } from '@socket.tech/ll-core';

// usage: npx hardhat run script/deploy-hop-router.ts --network polygon
export const deployHopL2RouterContract = async () => {
  try {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const socketGateway = '';

    console.log("deployer ", deployer);
    console.log("socketGateway", socketGateway);

    const factory = await ethers.getContractFactory('HopImplL2');
    const hopImplL2Contract = await factory.deploy(socketGateway);
    await hopImplL2Contract.deployed();
    console.log("hopImplL2Contract deployed at ", hopImplL2Contract.address);
    //0x403b5b01Ef2B45099a755eb09cca2A7A631fcC64

    await sleep(30);

    await run("verify:verify", {
      address: hopImplL2Contract.address,
      contract: `src/bridges/hop/l2/HopImplL2.sol:HopImplL2`,
      constructorArguments: [socketGateway],
    });


  } catch (error) {
    console.log("Error in deploying HopImplL2", error);
    return {
      success: false,
    };
  }
};

export const sleep = (delay: number) =>
  new Promise((resolve) => setTimeout(resolve, delay * 1000));

  deployHopL2RouterContract()
  .then(() => {
    console.log("✅ finished running the deployment of HopImplL2.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
