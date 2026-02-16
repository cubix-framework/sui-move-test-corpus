# Kriya AMM interface

This document provides guidance on integrating the Kriya AMM contract.

## Deployed addresses

| Network | Latest published at address                                        |
| ------- | ------------------------------------------------------------------ |
| mainnet | 0xa0eba10b173538c8fecca1dff298e488402cc9ff374f8a12ca7758eebe830b66 |
| testnet | 0xb5722117aec83525c71f84c31c1f28e29397feffa95c99cce72a150a555a63dd |

## Kriya protocol

This document will provide a comprehensive overview of the core features integral to the functionality of the Kriya AMM Interface.

### Structs

1. LP Token

```rust
struct KriyaLPToken<phantom X, phantom Y> has key, store {
    id: UID,
    pool_id: ID,
    lsp: Coin<LSP<X, Y>>
}

```

2. Pool

```rust

/// Kriya AMM Pool object.
struct Pool<phantom X, phantom Y> has key {
    id: UID,
    /// Balance of Coin<Y> in the pool.
    token_y: Balance<Y>,
    /// Balance of Coin<X> in the pool.
    token_x: Balance<X>,
    /// LP total supply share.
    lsp_supply: Supply<LSP<X, Y>>,
    /// Minimum required liquidity, non-withdrawable
    lsp_locked: Balance<LSP<X, Y>>,
    /// LP fee percent. Range[1-10000] (30 -> 0.3% fee)
    lp_fee_percent: u64,
    /// Protocol fee percent. Range[1-10000] (30 -> 0.3% fee)
    protocol_fee_percent: u64,
    /// Protocol fee pool to hold collected Coin<X> as fee.
    protocol_fee_x: Balance<X>,
    /// Protocol fee pool to hold collected Coin<Y> as fee.
    protocol_fee_y: Balance<Y>,
    /// If the pool uses the table_curve_formula
    is_stable: bool,
    /// 10^ Decimals of Coin<X>
    scaleX: u64,
    /// 10^ Decimals of Coin<Y>
    scaleY: u64,
    /// if trading is active for this pool
    is_swap_enabled: bool,
    /// if adding liquidity is enabled
    is_deposit_enabled: bool,
    /// if removing liquidity is enabled
    is_withdraw_enabled: bool
}

```

### Core Features Overview

1. Create Pool

- amm/sources/spot_dex.move

```rust

/// Creates pool with following arguments
public fun create_pool<X, Y>(
    protocol_configs: &ProtocolConfigs,
    is_stable: bool,
    coin_metadata_x: &CoinMetadata<X>,
    coin_metadata_y: &CoinMetadata<Y>,
    ctx: &mut TxContext
): Pool<X, Y> {}

```

2. Add liquidity

- amm/sources/spot_dex.move

```rust

/// Add liquidity to the `Pool`. Sender needs to provide both
/// `Coin<Y>` and `Coin<X>`, and in exchange he gets `Coin<LSP>` -
/// liquidity provider tokens.
public fun add_liquidity<X, Y>(
    pool: &mut Pool<X, Y>,
    token_y: Coin<Y>,
    token_x: Coin<X>,
    token_y_amount: u64,
    token_x_amount: u64,
    amount_y_min_deposit: u64,
    amount_x_min_deposit: u64,
    ctx: &mut TxContext
): KriyaLPToken<X, Y> {}

```

3. Remove liquidity

- amm/sources/spot_dex.move

```rust

/// Remove liquidity from the `Pool` by burning `Coin<LSP>`.
/// Returns `Coin<X>` and `Coin<Y>`.
public fun remove_liquidity<X, Y>(
    pool: &mut Pool<X, Y>,
    lp_token: KriyaLPToken<X, Y>,
    amount: u64,
    ctx: &mut TxContext
): (Coin<Y>, Coin<X>) {}

```

4. Swap X

- amm/sources/spot_dex.move

```rust

/// Swap `Coin<X>` for the `Coin<Y>`.
/// Returns the swapped `Coin<Y>`.
public fun swap_token_x<X, Y>(
    pool: &mut Pool<X, Y>, token_x: Coin<X>, amount: u64, min_recieve_y: u64, ctx: &mut TxContext
): Coin<Y> {}

```

5. Swap Y

- amm/sources/spot_dex.move

```rust

/// Swap `Coin<Y>` for the `Coin<X>`.
/// Returns Coin<X>.
public fun swap_token_y<X, Y>(
    pool: &mut Pool<X, Y>, token_y: Coin<Y>, amount: u64, min_recieve_x: u64, ctx: &mut TxContext
): Coin<X> {}

```

changes to move.toml to inlcude KriyaDEX as dependency.

```
[dependencies]
...
kriya_spot_dex = { git = "https://github.com/efficacy-finance/kriya-dex-interface.git", subdir = "./", rev = "latest", override = true }

[addresses]
kriya = "0xe10f85f47c6d11f63e650aa7daf168c55ead9abb6da4227eba5dd5e4f8d890b1"
```
