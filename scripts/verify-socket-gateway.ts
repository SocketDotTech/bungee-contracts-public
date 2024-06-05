import { ethers, run } from "hardhat";
const hre = require("hardhat");
import { addresses } from '@socket.tech/ll-core';

// usage: npx hardhat run script/verify-socket-gateway.ts --network polygon
export const verifySocketGatewayContract = async () => {
  try {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const owner = '0x2FA81527389929Ae9FD0f9ACa9e16Cba37D3EeA1';
    console.log("deployer ", deployer);
    console.log("owner", owner);
    await run("verify:verify", {
      address: '0xa530ed07c4cf14259a72093a87ac169d5d49e35a',
      contract: `src/SocketGateway.sol:SocketGateway`,
      constructorArguments: [owner],
    });

  } catch (error) {
    console.log("Error in verification of SocketGateway", error);
    return {
      success: false,
    };
  }
};

export const sleep = (delay: number) =>
  new Promise((resolve) => setTimeout(resolve, delay * 1000));

  verifySocketGatewayContract()
  .then(() => {
    console.log("✅ finished verification of SocketGateway.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
