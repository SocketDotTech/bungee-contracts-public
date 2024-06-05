import { ethers } from 'ethers';
import * as HopL2ABI from "../../../../../abi/bridges/hop/l2/HopL2.json";

//  npx ts-node tenderly/commands/run-deploy-hop-l2-route.ts
export const deployHopL2Route = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);

    const HopL2Factory = new ethers.ContractFactory(HopL2ABI.abi, HopL2ABI.bytecode, signer);
    const hopL2Contract = await HopL2Factory.deploy(socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await hopL2Contract.deployed();
    return hopL2Contract;
};
