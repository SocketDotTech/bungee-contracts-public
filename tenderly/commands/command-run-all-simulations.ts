import { executeSimulations } from "../simulations/execute-simulations";

//usage: npx ts-node tenderly/commands/command-run-all-simulations.ts
(async () => {
   const simulationResponsesWrapper = await executeSimulations();
   console.log(`Master Simulation-Response Wrapper is: ${JSON.stringify(simulationResponsesWrapper, null, 2)}`);

})().catch((e) => {
   console.error('error: ', e);
});