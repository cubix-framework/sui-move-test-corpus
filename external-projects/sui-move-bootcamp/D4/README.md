## Sui & Move Bootcamp <> Sui TS SDK | Introduction to Programmable Transactions

This exercise contains a simple Node project using Typescript, that executes a simple transaction block for transfering a SUI coin on the Sui blockchain.

### What is a PTB

On Sui, <i>[Programmable Transaction Blocks](https://docs.sui.io/concepts/transactions/prog-txn-blocks) are a lightweight and flexible way to allow a user to execute multiple commands (eg call multiple Move functions, manage their objects, and manage their coins) in a single transaction.</i>

### Useful Links

- [Programmable Transaction Blocks](https://docs.sui.io/concepts/transactions/prog-txn-blocks)
- [Sui TS SDK | Programmable Transaction Blocks](https://sdk.mystenlabs.com/typescript/transaction-building/basics)
- [Sui TS SDK | Passing inputs to a transaction](https://sdk.mystenlabs.com/typescript/transaction-building/basics#passing-inputs-to-a-transaction)

### Quickstart

- Create a .env file in the [ptbs/](./ptbs/) directory, following the structure of the [.env.example](./ptbs/.env.example):

```
SUI_NETWORK=https://rpc.testnet.sui.io:443
RECIPIENT_ADDRESS=0xCAFE
USER_SECRET_KEY=
```

- Run the following commands:

```
cd ptbs
npm i
npm run test
```

### Instructions

- Notice that both of the tests in the [transferSUI.test.ts](./ptbs/src/tests/transferSUI.test.ts) file are failing:
  - `Transaction Status`: Validates that the status of the transfer transaction is "success".
  - `SUI Balance Changes`: Parses the balance changes and validate they have changed as expected

#### 1. Transfer the amount

- Modify the [src/helpers/transferSUI.ts](./ptbs/src/helpers/transferSUI.ts) function, by adding the actual commands:
  - You should use the `tx.splitCoins` method to create the coin that is going to be transferred
  - You should use the `tx.gas` object to access the gas coin of the transaction, and use it as the initial input coin
  - You should use the `tx.transferObjects` method to transfer the coin to the recipient address
- Add the corresponding `options` to the arguments of the `signAndExecuteTransaction` method, so that we get access to the `effects` and the `balanceChanges`

#### 2. Parse the balance changes for the recipient

- Modify the [src/helpers/parseBalanceChanges.ts](./ptbs/src/helpers/parseBalanceChanges.ts) function:
  - You should filter the balanceChanges based on the `owner.AddressOwner` and `coinType` fields
  - You can use the `SUI_TYPE_ARG` constant that is exposed by `"@mysten/sui/utils"` to avoid using a hard-coded SUI coin type
