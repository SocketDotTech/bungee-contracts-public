import { ethers } from 'ethers';
import * as StargateImplL1ABI from "../../../../../abi/bridges/stargate/l1/StargateImplL1.json";

const router = '0x8731d54E9D02c286767d56ac03e8037C07e01e98';
const routerETH = '0x150f94B44927F078737562f0fcF3C95c01Cc2376';

//  npx ts-node tenderly/commands/run-deploy-stargate-l1-route.ts
export const deployStargateL1Route = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    const StargateImplL1Factory = new ethers.ContractFactory(StargateImplL1ABI.abi, StargateImplL1ABI.bytecode, signer);
    const stargateImplL1Contract = await StargateImplL1Factory.deploy(router, routerETH, socketGatewayAddress,
        {
            // gasLimit: 600000,
            // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
        });
    await stargateImplL1Contract.deployed();
    return stargateImplL1Contract;
};
