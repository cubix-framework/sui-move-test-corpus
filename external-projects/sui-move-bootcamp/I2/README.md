# [I2]: Fixed Supply

## What You Will Learn

In this section, you will learn how to implement a fixed supply fungible token in Move. You will:

- Initialize a coin with a fixed total supply and transfer it to the creator
- Lock the supply to prevent further minting using dynamic fields and freezing
- Burn the upgrade cap to make the package immutable and non-upgradable

By the end, you will understand how to enforce strict supply and upgrade constraints for tokens in Move.

## Project Structure

The codebase consists of several key components:

1. `fixed_supply/sources/silver.move` - Contains the fixed supply Silver coin implementation
2. `publish/src/publish.ts` - Handles package publishing and testing
3. `fixed_supply/Move.toml` - Package configuration and dependencies

## Tasks to Complete

There are two main tasks to implement in this project:

### 1. Initialize Fixed Supply
In `silver.move`, implement the `init` function to:
- Mint the total supply of 10,000,000,000,000,000,000 coins
- Transfer the coins to the sender
- Lock the treasury cap inside a freezer as a dynamic object field
- Freeze the freezer to prevent further modifications

### 2. Burn Upgrade Cap
In `publish.ts`, modify the `publishPackage` function to:
- Burn the upgrade cap instead of transferring it
- This ensures the package cannot be upgraded in the future

## Useful Links

- [Coin Standard](https://docs.sui.io/standards/coin)
- [Create a Coin](https://docs.sui.io/guides/developer/coin)
