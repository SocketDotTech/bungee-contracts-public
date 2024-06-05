import { ethers } from 'ethers';
import * as StargateImplL2ABI from "../../../../../abi/bridges/stargate/l2/StargateImplL2.json";

const router = '0xB0D502E938ed5f4df2E681fE6E419ff29631d62b';
const routerETH = '0xB49c4e680174E331CB0A7fF3Ab58afC9738d5F8b';

//  npx ts-node tenderly/commands/run-deploy-stargate-l2-route.ts
export const deployStargateL2Route = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    const StargateImplL2Factory = new ethers.ContractFactory(StargateImplL2ABI.abi, StargateImplL2ABI.bytecode, signer);
    const stargateImplL2Contract = await StargateImplL2Factory.deploy(router, routerETH, socketGatewayAddress,
        {
            // gasLimit: 600000,
            // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
        });
    await stargateImplL2Contract.deployed();
    return stargateImplL2Contract;
};
