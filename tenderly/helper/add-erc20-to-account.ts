import {ethers} from 'ethers';
import ERC20ABI from "../../abi/ERC20.json";

export const addERC20Balance = async (provider: any, tokenAddress: string, account: string, tokenAmount: any) => {
    const signer = provider.getSigner();
    const signerAddress = await signer.getAddress();
    const erc20Contract = new ethers.Contract(tokenAddress , ERC20ABI.abi , signer);    

    // Keep in mind that every account is automatically unlocked when performing simulations.
    // This enables you to impersonate any address and send transactions. 
    const unsignedTx = await erc20Contract.populateTransaction.approve(signerAddress, tokenAmount);
    const transactionParameters = [{
        to: erc20Contract.address,
        from: ethers.constants.AddressZero,
        data: unsignedTx.data,
        gas: ethers.utils.hexValue(3000000),
        gasPrice: ethers.utils.hexValue(1),
        value: ethers.utils.hexValue(0)
    }];


    const txHash = await provider.send('eth_sendTransaction', transactionParameters);
    console.log("ERC20 approved allowance");

    const respTxTransfer = await erc20Contract.transferFrom(
        ethers.constants.AddressZero, account, tokenAmount
        , {
            gasLimit: 600000,
            gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
        });
    await respTxTransfer.wait();
    return respTxTransfer;
};
