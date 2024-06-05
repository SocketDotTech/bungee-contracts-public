import { ethers } from 'ethers';
import * as HyphenImplABI from "../../../../abi/bridges/hyphen/HyphenImpl.json";

const liquidityPoolManager = '0x2A5c2568b10A0E826BfA892Cf21BA7218310180b';

//  npx ts-node tenderly/commands/run-deploy-hyphen-route.ts
export const deployHyphenRoute = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);

    const HyphenFactory = new ethers.ContractFactory(HyphenImplABI.abi, HyphenImplABI.bytecode, signer);
    const hyphenContract = await HyphenFactory.deploy(liquidityPoolManager, socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await hyphenContract.deployed();
    return hyphenContract;
};
