import {ethers} from 'ethers';
import ERC20ABI from "../../abi/ERC20.json";

export const getERC20Balance = async (provider: any, tokenAddress: string, account: string) => {
    const signer = provider.getSigner();
    const erc20Contract = new ethers.Contract(tokenAddress , ERC20ABI.abi , signer);    
    return await erc20Contract.balanceOf(account);
};
