import { ethers } from 'ethers';
import * as NativePolygonABI from "../../../../abi/bridges/native-polygon/NativePolygon.json";

const rootChainManagerProxy = '0xA0c68C638235ee32657e8f720a23ceC1bFc77C77';
const erc20PredicateProxy = '0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf';

//  npx ts-node tenderly/commands/run-deploy-native-polygon-route.ts
export const deployNativePolygonRoute = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);
    const deployer = await signer.getAddress();

    const NativePolygonFactory = new ethers.ContractFactory(NativePolygonABI.abi, NativePolygonABI.bytecode, signer);
    const nativePolygonContract = await NativePolygonFactory.deploy(rootChainManagerProxy, erc20PredicateProxy, socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await nativePolygonContract.deployed();
    const nativePolygonContractAddress = nativePolygonContract.address;

    return nativePolygonContract;
};
