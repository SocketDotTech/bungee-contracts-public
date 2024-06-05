import {ethers} from 'ethers';
import ERC20ABI from "../../abi/ERC20.json";
import { getERC20Balance } from './get-erc20-balance';

export const transferERC20 = async (provider: any, tokenAddress: string, sender: string, recipient: string, tokenAmount: any) => {
    const signer = provider.getSigner(sender);
    const erc20Contract = new ethers.Contract(tokenAddress , ERC20ABI.abi , signer);    

    const erc20Balance = await getERC20Balance(provider, tokenAddress, sender);
    if(erc20Balance < tokenAmount){
       throw new Error(`Failed as balance of sender: ${sender} - ${erc20Balance} is less than tokenAmount: ${tokenAmount}`);
    }
 
    // Keep in mind that every account is automatically unlocked when performing simulations.
    // This enables you to impersonate any address and send transactions. 
    const unsignedTx = await erc20Contract.populateTransaction.transfer(recipient, tokenAmount);
    const transactionParameters = [{
        to: erc20Contract.address,
        from: sender,
        data: unsignedTx.data,
        gas: ethers.utils.hexValue(3000000),
        gasPrice: ethers.utils.hexValue(1),
        value: ethers.utils.hexValue(0)
    }];

    const txHash = await provider.send('eth_sendTransaction', transactionParameters);
};
