import { addRoute } from "../deployments/add-route";
import { deployNativePolygonRoute } from "../deployments/bridges/native-polygon/deploy-native-polygon-route";
import { deploySocketGateway } from "../deployments/deploy-socket-gateway";
import { deleteForkById } from "../helper/delete-fork-id";
import { getForkProvider } from "../helper/get-fork-provider";
import { querySocketGateway } from "../helper/query-socket-gateway";

//usage: npx ts-node tenderly/commands/run-prepare-native-polygon-route.ts
(async () => {
   const providerResponse = await getForkProvider(1, 14386017);
   const provider = providerResponse.provider;
   const owner = '0x2FA81527389929Ae9FD0f9ACa9e16Cba37D3EeA1';

   // deploy socketgateway
   const socketGatewayInstance = await deploySocketGateway(provider);
   const socketGatewayAddress = socketGatewayInstance.address;

   // deploy Native Polygon
   const nativePolygonInstance = await deployNativePolygonRoute(provider, socketGatewayAddress);
   const nativePolygonRouteAddress = nativePolygonInstance.address;

   // add Native Polygon route to SocketGateway
   await addRoute(provider, socketGatewayAddress, owner, nativePolygonRouteAddress);

   //query added route
   const routeDetails = await querySocketGateway(provider, socketGatewayAddress, 0);
   console.log(`NativePolygon Route queried from SocketGateway is: ${routeDetails}`);

   const forkId = providerResponse.forkId;
   await deleteForkById(forkId);
})().catch((e) => {
   console.error('error: ', e);
});