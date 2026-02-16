# Pokémon Marketplace – Sui Move Tutorial

A sample Sui Move smart contract demonstrating core features of the Sui blockchain’s resource model, vector handling, event emission, and best practices for writing robust on‐chain modules.

---

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installing the Sui CLI](#installing-the-sui-cli)
4. [Configuring for Testnet & Acquiring Test SUI](#configuring-for-testnet--acquiring-test-sui)
5. [Building & Publishing](#building--publishing)
6. [Demo: Calling Marketplace Functions](#demo-calling-marketplace-functions)
7. [Additional Resources](#additional-resources)
8. [Contributing](#contributing)
9. [License](#license)

---

## Features

- **`Marketplace` resource** tracks fees, total volume, frozen state, minted count, and active listings
- **`Card` resource** encapsulates NFT metadata (`name`, `pokemon_type`, `minted_at`) and sale state
- **Core entry functions**
  - `new` – mint a new card NFT
  - `list_card` / `delist_card` – escrow and un-escrow listings
  - `buy_card` – purchase a listed card, splitting fees & proceeds
- **Helper functions**
  - `get_listings` – returns all active listing IDs
- **Events** for lifecycle hooks (`MarketplaceCreated`, `CardCreated`, `CardListed`, `CardPurchased`)
- **Admin‐only controls** (`update_fee`, `toggle_freeze`) secured by an `AdminCap`

---

## Prerequisites
- A funded Sui Testnet wallet (get free SUI via faucet)
- Sui CLI v1.46.2+
---

## Installing the Sui CLI

Install the official Sui CLI to interact with the network:

```bash
# macOS via homebrew
brew install sui

# Windows via Chocolatey
choco install sui
```

Verify installation:

```bash
sui --version
```

---

## Configuring for Testnet & Acquiring Test SUI

1. **Ensure CLI is pointed at Testnet**
   By default, the first time you run any `sui client` command you’ll be prompted for an RPC URL.
   - To list environments:
     ```bash
     sui client envs
     ```
   - To switch explicitly:
     ```bash
     sui client switch --env testnet
     ```

2. **Request test SUI from the faucet**
   - Official web UI: https://faucet.sui.io/

3. **Verify your Testnet balance**
   ```bash
   sui client gas
   ```
   Ensure you see your newly minted Testnet SUI before proceeding.

---

## Building & Publishing

1. **Clone the repository**
   ```bash
   git clone https://github.com/pawankumargali/pokemon-marketplace.git
   cd pokemon-marketplace
   ```

2. **Build the Move package**
   ```bash
   sui move build
   ```

3. **Publish to Testnet**
   ```bash
   sui client publish --gas-budget 10000000
   ```
   - Note the returned **package ID** (e.g., `0x3b02…be97c`) for function calls.

4. **View on Testnet Explorer**
   https://testnet.suivision.xyz/package/<YOUR_PACKAGE_ID>?tab=Code

---

## Demo: Calling Marketplace Functions

Replace `<PACKAGE_ID>`, `<MARKET_ID>`, and `<CARD_ID>` with your actual IDs.

### Mint a New Card

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module marketplace \
  --function new \
  --args "Charmander" "Fire" <MARKET_ID> \
  --gas-budget 1000000
```

### List a Card for Sale

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module marketplace \
  --function list_card \
  --args <CARD_ID> 1000000 <MARKET_ID> \
  --gas-budget 1000000
```


## Reference Resources

- [Getting Started with Sui](https://docs.sui.io/guides/developer/getting-started)
- [Sui CLI Cheat Sheet](https://docs.sui.io/doc/sui-cli-cheatsheet.pdf)

---


Feel free to explore further—happy coding on Sui!
