import { createFork } from './create-fork';

export const getForkProvider = async (networkId: number, blockNumber: number) => {
    const fork = await createFork(networkId, blockNumber);
    return { forkId: fork.forkId, provider: fork.forkProvider, forkBlockNumber: fork.forkAtBlockNumber };
};

export const getForkProviderForNetwork = async (networkId: number) => {
    return getForkProvider(networkId, 0);
};
