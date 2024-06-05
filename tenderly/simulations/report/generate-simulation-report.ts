import {getDateTimeString} from '../../utils/DateTimeUtils';
import * as fs from 'fs';
import {ensureFileSync} from 'fs-extra';
import { performance } from 'perf_hooks';

import { executeSimulations } from "../execute-simulations";

//usage: npx ts-node tenderly/simulations/report/generate-simulation-report.ts
(async () => {
    var startTime = performance.now();
    const simulationResponsesWrapper = await executeSimulations();
    var endTime = performance.now();

    console.log(`simulation data generation took ${(endTime - startTime) / 1000} seconds`);

    //append generated funds json to file
    const simulationResponsesWrapperFormatted = JSON.stringify(simulationResponsesWrapper, null, '\t');
    const dateTimeString = getDateTimeString();

    const simulationReportPath = `./reports/simulations/Simulation_${dateTimeString}.json`;
    ensureFileSync(simulationReportPath);
    fs.writeFileSync(simulationReportPath, simulationResponsesWrapperFormatted);
    console.log(`simulationReport generated at: ${simulationReportPath}`);
})().catch((e) => {
    console.error('error: ', e);
});