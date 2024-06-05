import { ethers } from 'ethers';
import * as HopL1ABI from "../../../../../out/HopImplL1.sol/HopImplL1.json";

//  npx ts-node tenderly/commands/run-deploy-hop-l1-route.ts
export const deployHopL1Route = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);

    const HopL1Factory = new ethers.ContractFactory(HopL1ABI.abi, HopL1ABI.bytecode, signer);
    const hopL1Contract = await HopL1Factory.deploy(socketGatewayAddress, socketGatewayAddress, {
        // gasLimit: 600000, 
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await hopL1Contract.deployed();
    return hopL1Contract;
};
