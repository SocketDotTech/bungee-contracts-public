import { ethers, run } from 'hardhat';
const hre = require("hardhat");

// usage: npx hardhat run script/deploy-socket-gateway.ts --network polygon
export const deploySocketGatewayContract = async () => {
  try {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const owner = '0x2FA81527389929Ae9FD0f9ACa9e16Cba37D3EeA1';

    console.log("deployer ", deployer);
    console.log("owner", owner);

    const factory = await ethers.getContractFactory('SocketGateway');
    const socketGatewayContract = await factory.deploy(owner);
    console.log("about to deploy SocketGateway");
    await socketGatewayContract.deployed();

    await sleep(30);

    await run("verify:verify", {
      address: socketGatewayContract.address,
      contract: `src/SocketGateway.sol:SocketGateway`,
      constructorArguments: [owner],
    });


  } catch (error) {
    console.log("Error in deploying socketGatewayContract", error);
    return {
      success: false,
    };
  }
};

export const sleep = (delay: number) =>
  new Promise((resolve) => setTimeout(resolve, delay * 1000));

  deploySocketGatewayContract()
  .then(() => {
    console.log("✅ finished running the deployment of SocketGateway.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
