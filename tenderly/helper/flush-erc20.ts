import { getERC20Balance } from "./get-erc20-balance";
import { transferERC20 } from "./transfer-erc20";

export const flushERC20 = async (provider: any, token: string, account: string) => {
    const flushAddress = '0x174D5bdb5011b1D19986a77F3d8475b7F15b6a9B';
    const erc20Balance = await getERC20Balance(provider, token, account);
    await transferERC20(provider, token, account, flushAddress, erc20Balance);
};
