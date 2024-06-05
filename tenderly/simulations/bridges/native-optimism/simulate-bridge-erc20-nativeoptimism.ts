import { ethers } from 'ethers';
import { addRoute } from "../../../deployments/add-route";
import { deployNativeOptimismRoute } from "../../../deployments/bridges/native-optimism/deploy-native-optimism-route";
import { deploySocketGateway } from "../../../deployments/deploy-socket-gateway";
import * as NativeOptimismABI from "../../../../abi/bridges/native-optimism/NativeOptimism.json";
import { addERC20Allowance } from '../../../helper/add-erc20-allowance';
import { addNativeBalance } from '../../../helper/add-native-balance';
import { transferERC20 } from '../../../helper/transfer-erc20';
import { BridgeCodes, BridgeType, ChainCodes, ChainCodeToChainId, SimulationResponse, TokenCodes, Tokens, TokenType } from '../../../../static-data/ll-static-data';

export const simulateBridgeERC20OnNativeOptimism = async (provider: any, forkBlockNumber: number, sourceChain: ChainCodes, destinationChain: ChainCodes, sender: string, socketGatewayOwner: string) => {
  const sourceChainId: number = ChainCodeToChainId.get(sourceChain) as number;
  const destinationChainId: number = ChainCodeToChainId.get(destinationChain) as number;
  const bridgeType: BridgeType = BridgeType.BRIDGE;
  const bridgeName: BridgeCodes = BridgeCodes.NATIVE_OPTIMISM;
  const tokenType: TokenType = TokenType.ERC20;
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

    // deploy Native Optimism
    const nativeOptimismInstance = await deployNativeOptimismRoute(provider, socketGatewayAddress, sender);
    const nativeOptimismRouteAddress = nativeOptimismInstance.address;

    // add Native Optimism route to SocketGateway
    await addRoute(provider, socketGatewayAddress, socketGatewayOwner, nativeOptimismRouteAddress);

    const recipient = "0xcd4FaEC53142e37f657d7b44504de8ed13Af40Ba";
    const _customBridgeAddress = '0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1';
    const _l2Token = '0x7F5c764cBc14f9669B88837ca1490cCa17c31607';
    const bridgingAmount = 1000000000;
    const bridgingValue = 0;
    const _interfaceId = 1;
    const _l2Gas = 2000000;
    const _currencyKey = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const _data = "0x";

    const bridgeAbiInterface = new ethers.utils.Interface(NativeOptimismABI.abi);
    const bridgeImplData = bridgeAbiInterface.encodeFunctionData('bridgeERC20ExternalTo',
      [[token, recipient, _customBridgeAddress, _l2Token, bridgingAmount,
        bridgingValue, _interfaceId, _currencyKey, _l2Gas, _data]]);

    const senderSigner = provider.getSigner(sender);

    await addNativeBalance(provider, sender, ethers.utils.parseEther('1'));

    const usdc_whale = '0xDa9CE944a37d218c3302F6B82a094844C6ECEb17';
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
      throw new Error("NativeOptimism ERC20-Bridge simulation failed");
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
