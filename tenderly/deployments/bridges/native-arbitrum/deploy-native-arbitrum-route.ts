import { ethers } from 'ethers';
import * as NativeArbitrumABI from "../../../../abi/bridges/native-arbitrum/NativeArbitrum.json";
const nativeArbitrumRouterAddress = '0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef';

//  npx ts-node tenderly/commands/run-deploy-native-arbitrum-route.ts
export const deployNativeArbitrumRoute = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    const NativeArbitrumFactory = new ethers.ContractFactory(NativeArbitrumABI.abi, NativeArbitrumABI.bytecode, signer);
    const nativeArbitrumContract = await NativeArbitrumFactory.deploy(nativeArbitrumRouterAddress, socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await nativeArbitrumContract.deployed();
    return nativeArbitrumContract;
};
