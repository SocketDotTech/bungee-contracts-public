import { deploySocketGateway } from "../deployments/deploy-socket-gateway";
import { deleteForkById } from "../helper/delete-fork-id";
import { getForkProvider } from "../helper/get-fork-provider";

//usage: npx ts-node tenderly/commands/run-deploy-socket-gateway.ts
(async () => {
   const providerResponse = await getForkProvider(1, 14386017);
   const provider = providerResponse.provider;

   const SocketGatewayDeployed = await deploySocketGateway(provider);
   console.log(`SocketGatewayDeployed is : ${SocketGatewayDeployed.address}`);

   const forkId = providerResponse.forkId;
   await deleteForkById(forkId);
})().catch((e) => {
   console.error('error: ', e);
});