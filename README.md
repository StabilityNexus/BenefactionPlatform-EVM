# Bene: Fundraising Platform

## Overview

Bene: Fundraising Platform is a decentralized application (DApp) that enables projects to receive funding in exchange for Proof of funding tokens. This DApp allows projects to request ETH(native currency of the network) in exchange for Proof of funding tokens.

#### Path to smart contracts: 
BenefactionPlatform-EVM/packages/hardhat/contracts/

#### Smart Contracts citrea Testnet Address:
FundingVault Factory: 0x7be12F651D421Edf31fd6488244aC20e8cEb5987


### How it Works

- Each project contains two tokens:
   1. **Auxiliary Project Token (APT)**: This token is minted during the project creation transaction and serves a main purposes:
     
      - **Contribution Tracking**: Temporarily, contributors receive this token when participating in the project. Once it is confirmed that a refund is no longer possible, contributors can exchange the APT for the **Proof-funding Token (PFT)**.
      - The total supply of APT equals the total issuance of PFT.
   2. **Proof-funding Token (PFT)**: Unlike the APT, the PFT is not minted on the contract. It represents the project or its organization and may also reflect proof-funding for similar projects within the same organization. PFTs are distributed only after refund conditions are no longer applicable, ensuring proper tracking. 

>The use of the APT ensures that during refunds, the origin of the token can be reliably traced to the current project. If PFTs were distributed immediately upon purchase, distinguishing whether a token originated from the current project or another related project would not be possible.

- Project owners can create a funding vault that holds an amount of tokens, which may vary, setting a **timestamp** as a deadline.
- A minimum amount of tokens must be sold before the project can withdraw funds. This ensures that the project receives sufficient backing.
- If the timestamp is reached before minimum amount of tokens are sold, users have the option to exchange their tokens back for the corresponding ETHs, provided the minimum has not been reached.

## Parameters of a funding vault

- **timestamp**: The timestamp limit until withdrawal or refund is allowed.
- **Minimum Funding Amount**: The minimum number of ETH needs to be raised to enable withdrawals or refunds.
- **Proof of funding Token Address**: The smart contract address for the Proof-of-Funding token (e.g., 0x123...abc)
- **Proof of funding Token Amount**: Total Proof of funding tokens for the vault
- **ETH/Token Exchange Rate**: The exchange rate of ETHs per token.
- **Withdrawl Address**: The address to withdraw funds after raised successfully. 
- **Project Title**: Title of the Project
- **Project URL**: URL of the Project
- **Project Description**: Description of the Project

### Constants

The following constants are defined in the contract:

- **Developer Address** (`dev_addr`): The base58 address of the developer.
- **Developer Fee** (`dev_fee`): The percentage fee taken by the developer (e.g., `5` for 5%).



## Processes
The Bene: Fundraising Platform supports seven main processes:

1. **funding vault Creation**: 
   - Allows anyone to create a funding vault with the specified script and parameters.
   - The funding vault represents the project's request for funds in exchange for a specific amount of tokens.
   - The tokens in the funding vault are provided by the funding vault creator, that is, the project owner.

2. **Token Acquisition**: 
   - Users are allowed to exchange ETHs for **Auxiliary Project Tokens (APTs)** (at the R7 exchange rate) until there are no more tokens left, even if the deadline has passed.
   - Users receive APTs in their own funding vaultes, which adhere to token standards, making them visible and transferable through ETH wallets.

3. **Refund Tokens**: 
   - Users are allowed to exchange APTs for ETHs (at the  exchange rate) if and only if the deadline has passed and the minimum number of tokens has not been sold.
   - This ensures that participants can retrieve their contributions if the funding goal is not met.

4. **Withdraw ETHs**: 
   - Project owners are allowed to withdraw ETHs if and only if the minimum number of tokens has been sold.
   - Project owners can only withdraw to the address specified in `withdrawl_address`.

5. **Withdraw Unsold Tokens**:
   - Project owners are allowed to withdraw unsold PFTs from the contract at any time.
      
   - Project owners can only withdraw to the address specified in `withdrawl_address`.

6. **Add Tokens**:
   - Project owners are allowed to add more APTs to the contract at any time.

7. **Redeem Tokens**:
   - Users are allowed to exchange **Auxiliary Project Tokens (APTs)** for **Proof-funding Tokens (PFTs)** if and only if the deadline has passed and the minimum number of tokens has been sold.


## Usage

You can interact with the platform using the following webpage:

(https://bene-evm.stability.nexus/)




# 🏗 Scaffold-ETH 2

<h4 align="center">
  <a href="https://docs.scaffoldeth.io">Documentation</a> |
  <a href="https://scaffoldeth.io">Website</a>
</h4>

🧪 An open-source, up-to-date toolkit for building decentralized applications (dapps) on the Ethereum blockchain. It's designed to make it easier for developers to create and deploy smart contracts and build user interfaces that interact with those contracts.

⚙️ Built using NextJS, RainbowKit, Hardhat, Wagmi, Viem, and Typescript.

- ✅ **Contract Hot Reload**: Your frontend auto-adapts to your smart contract as you edit it.
- 🪝 **[Custom hooks](https://docs.scaffoldeth.io/hooks/)**: Collection of React hooks wrapper around [wagmi](https://wagmi.sh/) to simplify interactions with smart contracts with typescript autocompletion.
- 🧱 [**Components**](https://docs.scaffoldeth.io/components/): Collection of common web3 components to quickly build your frontend.
- 🔥 **Burner Wallet & Local Faucet**: Quickly test your application with a burner wallet and local faucet.
- 🔐 **Integration with Wallet Providers**: Connect to different wallet providers and interact with the Ethereum network.

![Debug Contracts tab](https://github.com/scaffold-eth/scaffold-eth-2/assets/55535804/b237af0c-5027-4849-a5c1-2e31495cccb1)

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.18)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Clone this repo & install dependencies

```
git clone https://github.com/scaffold-eth/scaffold-eth-2.git
cd scaffold-eth-2
yarn install
```

2. Run a local network in the first terminal:

```
yarn chain
```

This command starts a local Ethereum network using Hardhat. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `hardhat.config.ts`.

3. On a second terminal, deploy the test contract:

```
yarn deploy
```

This command deploys a test smart contract to the local network. The contract is located in `packages/hardhat/contracts` and can be modified to suit your needs. The `yarn deploy` command uses the deploy script located in `packages/hardhat/deploy` to deploy the contract to the network. You can also customize the deploy script.

4. On a third terminal, start your NextJS app:

```
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your smart contract using the `Debug Contracts` page. You can tweak the app config in `packages/nextjs/scaffold.config.ts`.

**What's next**:

- Edit your smart contract `YourContract.sol` in `packages/hardhat/contracts`
- Edit your frontend homepage at `packages/nextjs/app/page.tsx`. For guidance on [routing](https://nextjs.org/docs/app/building-your-application/routing/defining-routes) and configuring [pages/layouts](https://nextjs.org/docs/app/building-your-application/routing/pages-and-layouts) checkout the Next.js documentation.
- Edit your deployment scripts in `packages/hardhat/deploy`
- Edit your smart contract test in: `packages/hardhat/test`. To run test use `yarn hardhat:test`
- You can add your Alchemy API Key in `scaffold.config.ts` if you want more reliability in your RPC requests.

## Documentation

Visit our [docs](https://docs.scaffoldeth.io) to learn how to start building with Scaffold-ETH 2.

To know more about its features, check out our [website](https://scaffoldeth.io).

## Contributing to Scaffold-ETH 2

We welcome contributions to Scaffold-ETH 2!

Please see [CONTRIBUTING.MD](https://github.com/scaffold-eth/scaffold-eth-2/blob/main/CONTRIBUTING.md) for more information and guidelines for contributing to Scaffold-ETH 2.
