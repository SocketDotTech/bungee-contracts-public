export const getNativeBalance = async (provider: any, account: string) => {
    return await provider.getBalance(account);
};
