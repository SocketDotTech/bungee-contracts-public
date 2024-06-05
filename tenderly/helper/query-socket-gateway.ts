import { ethers, Contract } from 'ethers';
import * as SocketGatewayABI from "../../abi/SocketGateway.json";

//  npx ts-node tenderly/commands/run-query-socket-gateway.ts
export const querySocketGateway = async (provider: any, socketGatewayAddress: string, routeIndex: number) => {
    const signer = await provider.getSigner();

    const socketGatewayContractInstance = new Contract(
        socketGatewayAddress,
        SocketGatewayABI.abi,
        signer
    );

    const routeDetails = await socketGatewayContractInstance.getRoute(routeIndex);
    return routeDetails;
};
