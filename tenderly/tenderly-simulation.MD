# Tenderly - Simulation on fork

## Ensure .env contain essential tenderly configuration

- TENDERLY_ETH_FORK_RPC=
- TENDERLY_ETH_FORK_ID=
- TENDERLY_ETH_FORK_BLOCK_NUMBER=
- TENDERLY_POLYGON_FORK_RPC=
- TENDERLY_POLYGON_FORK_ID=
- TENDERLY_POLYGON_FORK_BLOCK_NUMBER=

## Mandatory step in simulation

- In case forking is done programatically, then
   - ensure forkId is deleted after all simulations on fork
   - forkId can be created afresh before each simulation for a specific network and forkNumber
   - To delete forkId, use helper function `deleteForkById` in script: `tenderly/helper/delete-fork-id.ts` 

## Generate JSON report for simulations

1. Report generation script for Simulations: [generate-simulation-report](./simulations/report/generate-simulation-report.ts)

2. execution steps:

```sh
npx ts-node tenderly/simulations/report/generate-simulation-report.ts
```

3. Report is generated in parent-directory of project workspace under path:
   [../reports/simulations](../reports/simulations) 

4. Each Report-file is unique and with fileName containing a String with DateAndTime at the moment the report is generated.

## Master-Script to run all simulations

1. Simulations are executed in a master script
   [execute-simulations](./simulations/execute-simulations.ts) 
2. Each scenario in a bridge is considered as a simulation and a script is made for that scenario
3. Fork for the Simulation is prepared in master script and fork is done per network and at a specific blockNumber
4. For all L1 based bridges, fork is done on ETH blockchain
   - networkId: 1
   - forked at BlockNumber: 16355397

5. For all L2 based bridges, fork is done on POLYGON blockchain
   - networkId: 137
   - forked at BlockNumber: 37785012

6. Tenderly providers are constructed and passed-in as arguments to the simulations.

7. To execute master-script for simulation, follow below shell command.

```sh
npx ts-node tenderly/simulations/execute-simulation.ts
```

## Bridge on Native-Polygon for Simulation

1. Deploy SocketGateway
2. Deploy Route-Implementation Contract
3. Add address of Route-Implementation as route to SocketGateway
4. Fund the sender with ERC20 tokens
5. sender to approve spending allowancer for the Socketgateway contract
6. call bridge function

- the steps are to be composed in sequence.

## Helper functions

### create fork-id

 - new fork can be constructed by calling function: `createFork` which takes `networkId` and `forkNumber`

- script location: [create-fork-id](./helper/create-fork-id.ts)

- sample command to generate forkId
```sh
npx ts-node tenderly/commands/command-generate-fork-id.ts
```

### get Fork provider

 - provider can be constructed by calling function: `getForkProvider` which takes `networkId` and `forkNumber`

- script location: [get-fork-provider](./helper/get-fork-provider.ts)

```sh
npx ts-node tenderly/commands/command-generate-fork-id.ts
```

### fund account with Native

 - function name: `addNativeBalance`
 
 - script location: [addNativeBalance](./helper/add-native-balance.ts)

 - function signature:
    1. provider
    2. recipient
    3. amountInWei

 - set the variables in the functions

 - provider can be constructed by calling function: `getForkProvider` which takes `networkId` and `forkNumber`

  - Sample command to understand the function call:

    ```sh
    npx ts-node tenderly/commands/transfer-eth-on-fork.ts
    ```
### set Allowance for ERC20 tokens

- To set allowance for spender call function `addERC20Allowance` in file: `add-erc20-allowance.ts`

- script location: [add-erc20-allowance](./helper/add-erc20-allowance.ts)

- function parameters are:
  1. provider
  2. tokenAddress
  3. ownerAccount
  4. spenderAccount
  5. allowanceAmount

- sample execution is provided in commands directory.
- you can tweak the numbers and addresses in the sample command provided below.

```sh
npx ts-node npx ts-node tenderly/commands/run-add-erc20-allowance.ts
```

### transfer ERC20 tokens

- To transfer ERC20 tokens call function: `transferERC20` in file: `transfer-erc20.ts`

- script location: [transfer-erc20](./helper/transfer-erc20.ts)

- function parameters are:
   1. provider
   2. tokenAddress
   3. sender
   4. recipient
   5. tokenAmount

- sample execution is provided in commands directory.
- you can tweak the numbers and addresses in the sample command provided below.

```sh
npx ts-node tenderly/commands/run-transfer-erc20.ts
```

### get ERC20 Balance

- To query ERC20 balance of an account call function: `getERC20Balance` in script file: `get-erc20-balance.ts`

 - script location: [get-erc20-balance](./helper/get-erc20-balance.ts)

- function parameters are:
   1. provider
   2. tokenAddress
   3. account

- sample execution is provided in commands directory.
- you can tweak the numbers and addresses in the sample command provided below.

```sh
npx ts-node tenderly/commands/command-get-erc20-balance.ts
```

### get ERC20 Allowance

- To query ERC20 Allowance for an account call function: `getERC20Allowance` in script file: `get-erc20-allowance.ts`

 - script location: [get-erc20-allowance](./helper/get-erc20-allowance.ts)

- function parameters are:
   1. provider
   2. tokenAddress
   3. ownerAccount
   4. spenderAccount

- sample execution is provided in commands directory.
- you can tweak the numbers and addresses in the sample command provided below.

```sh
npx ts-node tenderly/commands/command-get-erc20-allowance.ts
```


### fund account with ERC20 tokens

 - function name: `addERC20Balance`
 - transfers erc20 tokens to recipient
 - script location: [add-erc20-to-account](./helper/add-erc20-to-account.ts)
 - function signature:
    1. provider
    2. tokenAddress
    3. account
    4. tokenAmount

 - set the variables in the functions

 - provider can be constructed by calling function: `getForkProvider` which takes `networkId` and `forkNumber`

  - Sample command to understand the function call:

    ```sh
    npx ts-node tenderly/commands/fund-account-with-erc20.ts
    ```

### References:

programatic creation of fork and simulation on forked network:

[https://docs.tenderly.co/simulations-and-forks/simulation-api#2-create-a-fork-environment](https://docs.tenderly.co/simulations-and-forks/simulation-api#2-create-a-fork-environment)

forking a network from tenderly dashboard:

[https://docs.tenderly.co/simulations-and-forks/how-to-create-a-fork](https://docs.tenderly.co/simulations-and-forks/how-to-create-a-fork)

### Steps to simulate for ll-contracts:

1. Identify tenderly API configuration parameters
2. Create fork for a network programatically using tenderly API

[https://docs.tenderly.co/simulations-and-forks/simulation-api#2-create-a-fork-environment](https://docs.tenderly.co/simulations-and-forks/simulation-api#2-create-a-fork-environment)

2. refer to RPC URL of forked network from environment variables
3. Deploy `SocketGateway` on the fork using RPC URL
4. Deploy `route implementation` bridge on the fork 
5. Add address of `route implementation` to `Socketgateway` contract
6. Identify how to Impersonate the address or how to fund an address 
7. Approve `SocketGatway` for spending on funds
8. call bridge function on SocketGateway
9. Check gas cost in the transactionResponse
