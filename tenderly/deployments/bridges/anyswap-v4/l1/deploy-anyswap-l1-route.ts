import { ethers } from 'ethers';
import * as AnySwapL1ABI from "../../../../../abi/bridges/anyswap-v4/l1/AnySwapL1.json";

const router = '0x6b7a87899490EcE95443e979cA9485CBE7E71522';

//  npx ts-node tenderly/commands/run-deploy-anyswap-l1-route.ts
export const deployAnySwapRoute = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    const AnyswapL1Factory = new ethers.ContractFactory(AnySwapL1ABI.abi, AnySwapL1ABI.bytecode, signer);
    const anySwapL1Contract = await AnyswapL1Factory.deploy(router, socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await anySwapL1Contract.deployed();
    return anySwapL1Contract;
};
