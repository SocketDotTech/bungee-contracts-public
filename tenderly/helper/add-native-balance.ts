import {ethers} from 'ethers';

export const addNativeBalance = async (provider: any, recipient: string, amountInWei: any) => {
    const params = [
            [recipient],
             ethers.utils.hexValue(amountInWei.toHexString()) // hex encoded wei amount
    ];

    await provider.send('tenderly_addBalance', params);
};
