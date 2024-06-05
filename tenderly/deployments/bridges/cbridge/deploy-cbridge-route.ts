import { ethers } from 'ethers';
import * as CelerStorageWrapperABI from "../../../../abi/bridges/cbridge/CelerStorageWrapper.json";
import * as CelerImplABI from "../../../../abi/bridges/cbridge/CelerImpl.json";

const CELER_BRIDGE = '0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820';
const WETH_ADDRESS = '0x6B175474E89094C44Da98b954EedeAC495271d0F';

//  npx ts-node tenderly/commands/run-deploy-cbridge-route.ts
export const deployCBridgeRoute = async (provider: any, socketGatewayAddress: string, sender: string) => {
    const signer = await provider.getSigner(sender);

    const CelerStorageWrapperFactory = new ethers.ContractFactory(CelerStorageWrapperABI.abi, CelerStorageWrapperABI.bytecode, signer);
    const celerStorageWrapperContract = await CelerStorageWrapperFactory.deploy(socketGatewayAddress);
    await celerStorageWrapperContract.deployed();
    const celerStorageWrapperAddress = celerStorageWrapperContract.address;

    const CelerImplFactory = new ethers.ContractFactory(CelerImplABI.abi, CelerImplABI.bytecode, signer);
    const celerImplContract = await CelerImplFactory.deploy(CELER_BRIDGE, WETH_ADDRESS, celerStorageWrapperAddress, socketGatewayAddress, {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });
    await celerImplContract.deployed();
    return celerImplContract;
};
