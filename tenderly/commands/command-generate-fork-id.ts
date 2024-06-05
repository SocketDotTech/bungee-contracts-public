import {createFork} from "../helper/create-fork";

//usage: npx ts-node tenderly/commands/command-generate-fork-id.ts
(async () => {
   const fork = await createFork(1, 0);
   console.log(`forkId generated : ${fork.forkId}`);
})().catch((e) => {
   console.error('error: ', e);
});