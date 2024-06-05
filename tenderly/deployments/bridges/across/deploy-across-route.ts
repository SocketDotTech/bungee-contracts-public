import { ethers } from 'ethers';
import * as AcrossABI from "../../../../abi/bridges/across/Across.json";

const spokePoolAddress = '0x4D9079Bb4165aeb4084c526a32695dCfd2F77381';
const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';

//  npx ts-node tenderly/commands/run-deploy-across-route.ts
export const deployAcrossRoute = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    console.log(`deploying Across route`);
    const AcrossFactory = new ethers.ContractFactory(AcrossABI.abi, AcrossABI.bytecode, signer);
    const acrossContract = await AcrossFactory.deploy(spokePoolAddress, WETH, socketGatewayAddress,{
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await acrossContract.deployed();
    console.log(`deployed Across route`);
    return acrossContract;
};
