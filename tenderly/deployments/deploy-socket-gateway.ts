import { ethers } from 'ethers';
import * as SocketGatewayABI from "../../out/SocketGateway.sol/SocketGateway.json";
import { getNativeBalance } from '../helper/get-native-balance';

//  npx ts-node tenderly/commands/run-deploy-socket-gateway.ts
export const deploySocketGateway = async (provider: any, deployer: string, socketGatewayOwner: string) => {
    const signer = await provider.getSigner(deployer);
    const factory = new ethers.ContractFactory(SocketGatewayABI.abi, SocketGatewayABI.bytecode, signer);

    const nativeBalance = await getNativeBalance(provider, deployer);

    const socketGatewayContract = await factory.deploy(socketGatewayOwner,
    {
        // gasLimit: 1200000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });

    await socketGatewayContract.deployed();

    console.log(`deployed socketGateway`);
    return socketGatewayContract;
};
