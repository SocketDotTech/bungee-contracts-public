import { ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployHopL2Route } from "../../../../../deployments/bridges/hop/l2/deploy-hop-l2-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as HopL2ABI from "../../../../../../abi/bridges/hop/l2/HopL2.json";
import { addERC20Allowance } from '../../../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { transferERC20 } from '../../../../../helper/transfer-erc20';
import { ChainCodes, ChainCodeToChainId, Tokens, TokenCodes, BridgeType, BridgeCodes, TokenType, SimulationResponse } from '../../../../../../static-data/ll-static-data';
import { getERC20Balance } from '../../../../../helper/get-erc20-balance';

export const simulateBridgeERC20OnHopL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
  const sourceChainId = ChainCodeToChainId.get(sourceChain);
  const destinationChainId = ChainCodeToChainId.get(destinationChain);
  const bridgeType = BridgeType.BRIDGE;
  const bridgeName = BridgeCodes.HOP_L2;
  const tokenType = TokenType.ERC20;
  const tokenCode: TokenCodes = TokenCodes.USDC;
  //@ts-ignore
  const token = Tokens.get(tokenCode).get(sourceChain) as string;
  let gasUsed = 0;
  let isSuccessful = true;
  let errorMessage = "";

  try {
    // deploy socketgateway
    const socketGatewayInstance = await deploySocketGateway(provider, sender, socketGatewayOwner);
    const socketGatewayAddress = socketGatewayInstance.address;

    console.log(`deployed socketGateway`);

    // deploy HopL2 Arbitrum
    const hopL2Instance = await deployHopL2Route(provider, socketGatewayAddress, sender);
    const hopL2RouteAddress = hopL2Instance.address;

    // add HopL2 route to SocketGateway
    await addRoute(provider, socketGatewayAddress, socketGatewayOwner, hopL2RouteAddress);

    const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
    const _hopAMM = '0x76b22b8C1079A44F1211D867D68b1eda76a635A7';
    // fees passed to relayer
    const _bonderFee = 200000;
    const _amountOutMin = 40000000;
    const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
    const _deadline = Date.now() + 60 * 20;
    const _deadlineDestination = Date.now() + 60 * 20;
    const _amountOutMinDestination = 40000000;
    const bridgingAmount = 50000000;

    //sequence of arguments for implData: receiverAddress, token, amm, amount, destinationChainId, bonderfees, amountOutMin, _deadline,_amountOutMinDestination,_deadlineDestination
    const bridgeAbiInterface = new ethers.utils.Interface(HopL2ABI.abi);
    const bridgeImplData = bridgeAbiInterface.encodeFunctionData(
      'bridgeERC20ExternalTo',
      [[recipient, token, _hopAMM,
        bridgingAmount, destinationChainId,
        _bonderFee, _amountOutMin,
        _deadline, _amountOutMinDestination,
        _deadlineDestination]]);

    const senderSigner = provider.getSigner(sender);

    await addNativeBalance(provider, sender, ethers.utils.parseEther('1'));

    const usdc_whale = '0xC070A61D043189D99bbf4baA58226bf0991c7b11';
    await transferERC20(provider, token, usdc_whale, sender, bridgingAmount);
    await addERC20Allowance(provider, token, sender, socketGatewayAddress, bridgingAmount);

    const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
      {
        gasLimit: 600000,
        gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
      });

    const bridgeTxnHash = bridgeTxn.hash;

    const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

    if (!txnReceipt.status) {
        throw new Error("HopL2 ERC20-Bridge simulation failed");
    }

    gasUsed = txnReceipt.gasUsed.toString();
  } catch (e) {
    isSuccessful = false;
    errorMessage = (e as Error).message;
  }

  return <SimulationResponse>({
    bridgeName: BridgeCodes[bridgeName],
    bridgeType: BridgeType[bridgeType],
    tokenType: TokenType[tokenType],
    tokenCode: TokenCodes[tokenCode],
    gasUsed: gasUsed,
    isSuccessful: isSuccessful,
    errorMessage: errorMessage,
    sourceChainCode: ChainCodes[sourceChain],
    sourceChainId: sourceChainId,
    destinationChainCode: ChainCodes[destinationChain],
    destinationChainId: destinationChainId,
    tokenAddress: token
  });
};
