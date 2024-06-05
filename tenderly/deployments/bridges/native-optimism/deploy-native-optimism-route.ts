import { ethers } from 'ethers';
import * as NativeOptimismABI from "../../../../abi/bridges/native-optimism/NativeOptimism.json";

//  npx ts-node tenderly/commands/run-deploy-native-optimism-route.ts
export const deployNativeOptimismRoute = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    const deployer = await signer.getAddress();
    const NativeOptimismFactory = new ethers.ContractFactory(NativeOptimismABI.abi, NativeOptimismABI.bytecode, signer);
    const nativeOptimismContract = await NativeOptimismFactory.deploy(socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await nativeOptimismContract.deployed();
    return nativeOptimismContract;
};
