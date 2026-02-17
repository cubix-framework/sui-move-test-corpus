module typus_dov::typus_dov_single {
    use typus_framework::authority::Authority;
    use typus_framework::balance_pool::BalancePool;

    #[allow(unused)]
    public struct Registry has key {
        id: UID,
        num_of_vault: u64,
        authority: Authority,
        fee_pool: BalancePool,
        portfolio_vault_registry: UID, // 1
        deposit_vault_registry: UID, // 1
        auction_registry: UID, // num_of_vault
        bid_vault_registry: UID, // num_of_vault * round
        refund_vault_registry: UID, // n tokens
        additional_config_registry: UID,
        version: u64,
        transaction_suspended: bool,
    }
}