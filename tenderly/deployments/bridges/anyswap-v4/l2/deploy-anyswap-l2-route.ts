import { ethers } from 'ethers';
import * as AnySwapL2ABI from "../../../../../abi/bridges/anyswap-v4/l2/AnySwapL2.json";

const router = '0x4f3Aff3A747fCADe12598081e80c6605A8be192F';

//  npx ts-node tenderly/commands/run-deploy-anyswap-l2-route.ts
export const deployAnySwapL2Route = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    const AnyswapL2Factory = new ethers.ContractFactory(AnySwapL2ABI.abi, AnySwapL2ABI.bytecode, signer);
    const anySwapL2Contract = await AnyswapL2Factory.deploy(router, socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await anySwapL2Contract.deployed();
    return anySwapL2Contract;
};
