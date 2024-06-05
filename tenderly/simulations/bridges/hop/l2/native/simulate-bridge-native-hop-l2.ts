import { BigNumber, ethers } from 'ethers';
import { addRoute } from "../../../../../deployments/add-route";
import { deployHopL2Route } from "../../../../../deployments/bridges/hop/l2/deploy-hop-l2-route";
import { deploySocketGateway } from "../../../../../deployments/deploy-socket-gateway";
import * as HopL2ABI from "../../../../../../abi/bridges/hop/l2/HopL2.json";
import { addNativeBalance } from '../../../../../helper/add-native-balance';
import { getNativeBalance } from '../../../../../helper/get-native-balance';
import { NATIVE_TOKEN_ADDRESS, ChainCodes, ChainCodeToChainId, BridgeType, BridgeCodes, TokenType, TokenCodes, SimulationResponse } from '../../../../../../static-data/ll-static-data';

export const simulateBridgeNativeOnHopL2 = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {

  const token = NATIVE_TOKEN_ADDRESS;
  const sourceChainId = ChainCodeToChainId.get(sourceChain);
  const destinationChainId = ChainCodeToChainId.get(destinationChain);
  const bridgeType: BridgeType = BridgeType.BRIDGE;
  const bridgeName: BridgeCodes = BridgeCodes.HOP_L2;
  const tokenType: TokenType = TokenType.NATIVE;
  const tokenCode: TokenCodes = TokenCodes.NATIVE_TOKEN;
  let gasUsed = 0;
  let isSuccessful = true;
  let errorMessage = "";

  try {


  // deploy socketgateway
  const socketGatewayInstance = await deploySocketGateway(provider, sender, socketGatewayOwner);
  const socketGatewayAddress = socketGatewayInstance.address;

  // deploy HopL2 Arbitrum
  const hopL2Instance = await deployHopL2Route(provider, socketGatewayAddress, sender);
  const hopL2RouteAddress = hopL2Instance.address;

  // add HopL2 route to SocketGateway
  await addRoute(provider, socketGatewayAddress, socketGatewayOwner, hopL2RouteAddress);

    const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
    const _hopAMM = '0x884d1Aa15F9957E1aEAA86a82a72e49Bc2bfCbe3';
    // fees passed to relayer
    const _bonderFee = BigNumber.from("6000000000000000000")
    const _amountOutMin = ethers.utils.parseEther('15');
    const block_timestamp = (await provider.getBlock(forkBlockNumber)).timestamp;
    const _deadline = block_timestamp + 60 * 20;
    const _deadlineDestination = block_timestamp + 60 * 20;
    const _amountOutMinDestination = ethers.utils.parseEther('15');
    const bridgingAmount = ethers.utils.parseEther('100');
    const gasReserve = ethers.utils.parseEther('0.2');

    //sequence of arguments for implData: receiverAddress, token, amm, amount, destinationChainId, bonderfees, amountOutMin, _deadline,_amountOutMinDestination,_deadlineDestination
    const bridgeAbiInterface = new ethers.utils.Interface(HopL2ABI.abi);
    const bridgeImplData = bridgeAbiInterface.encodeFunctionData(
      'bridgeNativeExternalTo',
      [[recipient, token, _hopAMM,
        bridgingAmount, destinationChainId,
        _bonderFee, _amountOutMin,
        _deadline, _amountOutMinDestination,
        _deadlineDestination]]);

    const senderSigner = provider.getSigner(sender);
    await addNativeBalance(provider, sender, bridgingAmount.add(gasReserve));

    const bridgeTxn = await socketGatewayInstance.connect(senderSigner).bridge(0, bridgeImplData,
      {
        value: bridgingAmount,
        gasLimit: 600000,
        gasPrice: ethers.utils.parseUnits("50", "gwei").toNumber()
      });

    const bridgeTxnHash = bridgeTxn.hash;

    const txnReceipt = await provider.getTransactionReceipt(bridgeTxnHash);

    if (!txnReceipt.status) {
      throw new Error("HopL2 Native-Bridge simulation failed");
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
