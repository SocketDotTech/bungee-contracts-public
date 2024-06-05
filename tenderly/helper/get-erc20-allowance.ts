import {ethers} from 'ethers';
import ERC20ABI from "../../abi/ERC20.json";

export const getERC20Allowance = async (provider: any, tokenAddress: string, ownerAccount: string, spenderAccount: string) => {

    const signer = provider.getSigner();
    const daiContract = new ethers.Contract(tokenAddress , ERC20ABI.abi , signer);    

    const erc20Allowance = await daiContract.allowance(ownerAccount, spenderAccount);
    return erc20Allowance;
};
