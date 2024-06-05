import { Contract, ethers } from 'ethers';
import * as SocketGatewayABI from "../../abi/SocketGateway.json";
import { addNativeBalance } from '../helper/add-native-balance';

//  npx ts-node tenderly/commands/run-add-route.ts
export const addRoute = async (provider: any, socketGatewayAddress: string, socketGatewayOwner: string, routeAddress: string) => {

    await addNativeBalance(provider, socketGatewayOwner, ethers.utils.parseEther('0.3'));
    const signer = await provider.getSigner(socketGatewayOwner);

    const socketGatewayContractInstance = new Contract(
        socketGatewayAddress,
        SocketGatewayABI.abi,
        signer
    );

    const tx = await socketGatewayContractInstance.addRoute(routeAddress,
    {
        // gasLimit: 600000,
        // gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
    });

    await tx.wait();
};
