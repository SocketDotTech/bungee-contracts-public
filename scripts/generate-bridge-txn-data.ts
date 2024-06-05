import { ethers } from 'ethers';
import {SocketGatewayABI} from '../abi/SocketGateway';
import * as HopL1ABI from '../abi/HopL1.json';

//usage: npx ts-node scripts/generate-bridge-txn-data.ts
(async () => {
    const sender = "0x0E1B5AB67aF1c99F8c7Ebc71f41f75D4D6211e53";
    const USDC_Polygon = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

    const _hopAMM = '0x76b22b8C1079A44F1211D867D68b1eda76a635A7';
    // fees passed to relayer
    const _bonderFee = 200000;
    const _amountOutMin = 40000000;
    const _deadline = 1672235236 + 100000;
    const _amountOutMinDestination = 40000000;
    const _deadlineDestination = 1672235236 + 100000;
    const _amount = 50000000;
    const _toChainId = 42161;

    const bridgeAbiInterface = new ethers.utils.Interface(HopL1ABI.abi);
  
     const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20ExternalTo', [[sender,USDC_Polygon,_hopAMM,_amount,_toChainId,_bonderFee,_amountOutMin,
                                                                                      _deadline,_amountOutMinDestination,_deadlineDestination]]);

    console.log(`HopL1 bridgeAbiTxn: ${JSON.stringify(bridgeImplData)}`);

    const socketGatewayAbiInterface = new ethers.utils.Interface(SocketGatewayABI);

    const bridgeTxnData = socketGatewayAbiInterface.encodeFunctionData('bridge', [0, bridgeImplData]);

    console.log(`HopL1 bridgeTxnData: ${JSON.stringify(bridgeTxnData)}`);
})().catch((e) => {
   console.error('error: ', e);
});