import { ethers, run } from "hardhat";
const hre = require("hardhat");
import { addresses } from '@socket.tech/ll-core';

// usage: npx hardhat run script/verify-hop-l2-router.ts --network polygon
export const verifyHopImplL2Contract = async () => {
  try {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const socketGateway = '0xa530ed07C4cf14259a72093A87Ac169D5d49e35a';
    console.log("deployer ", deployer);
    console.log("socketGateway", socketGateway);

    await run("verify:verify", {
      address: '0x403b5b01Ef2B45099a755eb09cca2A7A631fcC64',
      contract: `src/bridges/hop/l2/HopImplL2.sol:HopImplL2`,
      constructorArguments: [socketGateway],
    });

  } catch (error) {
    console.log("Error in verification of HopImplL2", error);
    return {
      success: false,
    };
  }
};

export const sleep = (delay: number) =>
  new Promise((resolve) => setTimeout(resolve, delay * 1000));

  verifyHopImplL2Contract()
  .then(() => {
    console.log("✅ finished verification of HopImplL2.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
