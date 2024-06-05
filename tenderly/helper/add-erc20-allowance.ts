import {ethers} from 'ethers';
import ERC20ABI from "../../abi/ERC20.json";
import { getERC20Balance } from './get-erc20-balance';

export const addERC20Allowance = async (provider: any, tokenAddress: string, ownerAccount: string, spenderAccount: string, allowanceAmount: any) => {
    const signer = provider.getSigner(ownerAccount);
    const daiContract = new ethers.Contract(tokenAddress , ERC20ABI.abi , signer);    

    const erc20Balance = await getERC20Balance(provider, tokenAddress, ownerAccount);
    if(erc20Balance < allowanceAmount){
       throw new Error(`Failed as balance of owner-account: ${ownerAccount} - ${erc20Balance} is less than allowanceAmount: ${allowanceAmount}`);
    }
 
    // Keep in mind that every account is automatically unlocked when performing simulations.
    // This enables you to impersonate any address and send transactions. 
    const unsignedTx = await daiContract.populateTransaction.approve(spenderAccount, allowanceAmount);
    const transactionParameters = [{
        to: daiContract.address,
        from: ownerAccount,
        data: unsignedTx.data,
        gas: ethers.utils.hexValue(3000000),
        gasPrice: ethers.utils.hexValue(1),
        value: ethers.utils.hexValue(0)
    }];

    const txHash = await provider.send('eth_sendTransaction', transactionParameters);
};
