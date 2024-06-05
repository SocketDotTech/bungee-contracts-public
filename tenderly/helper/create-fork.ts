import axios from 'axios';
import {ethers} from 'ethers';
import dotenv from 'dotenv';

dotenv.config();
const TENDERLY_USER = process.env.TENDERLY_USER;
const TENDERLY_PROJECT = process.env.TENDERLY_PROJECT;
const TENDERLY_FORK_API = `https://api.tenderly.co/api/v1/account/${TENDERLY_USER}/project/${TENDERLY_PROJECT}/fork`;
const TENDERLY_ACCESS_KEY = process.env.TENDERLY_ACCESS_KEY;

export const createFork = async (networkId: number, blockNumber: number) => {
    // set up your access-key, if you don't have one or you want to generate new one follow next link
    // https://dashboard.tenderly.co/account/authorization
    const opts = {
        headers: {
            'X-Access-Key': TENDERLY_ACCESS_KEY as string,
        }
    }

    let body;

    if(blockNumber == 0){
        body = {
            "network_id": networkId
        }
    } else {
        body = {
            "network_id": networkId,
            "block_number": blockNumber
        }
    }

    const tenderlyForkResponse = await axios.post(TENDERLY_FORK_API, body, opts);
    const forkId = tenderlyForkResponse.data.simulation_fork.id;
    const forkedAtBlockNumber = tenderlyForkResponse.data.simulation_fork.block_number;
    const forkRpcURL = `https://rpc.tenderly.co/fork/${forkId}`;
    const forkProvider = new ethers.providers.JsonRpcProvider(forkRpcURL);

    return {
        networkId: networkId, 
        forkId: forkId,
        forkAtBlockNumber: forkedAtBlockNumber,
        forkRpcURL: forkRpcURL,
        forkProvider: forkProvider
    }
};
