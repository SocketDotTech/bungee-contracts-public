import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();
const TENDERLY_USER = process.env.TENDERLY_USER;
const TENDERLY_PROJECT = process.env.TENDERLY_PROJECT;
const TENDERLY_ACCESS_KEY = process.env.TENDERLY_ACCESS_KEY;

export const deleteForkById = async (forkId: any) => {
    // set up your access-key, if you don't have one or you want to generate new one follow next link
    // https://dashboard.tenderly.co/account/authorization
    const opts = {
        headers: {
            'X-Access-Key': TENDERLY_ACCESS_KEY as string,
        }
    }

    const TENDERLY_FORK_ACCESS_URL = `https://api.tenderly.co/api/v1/account/${TENDERLY_USER}/project/${TENDERLY_PROJECT}/fork/${forkId}`

    await axios.delete(TENDERLY_FORK_ACCESS_URL, opts)
};
