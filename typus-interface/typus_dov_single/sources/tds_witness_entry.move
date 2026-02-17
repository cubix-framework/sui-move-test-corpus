module typus_dov::tds_witness_entry {
    use sui::balance::Balance;
    use sui::clock::Clock;

    use typus_dov::typus_dov_single::Registry;
    use typus_framework::vault::TypusBidReceipt;

    #[allow(unused)]
    public fun otc<W: drop, D_TOKEN, B_TOKEN>(
        witness: W,
        signature: vector<u8>,
        registry: &mut Registry,
        index: u64,
        price: u64,
        size: u64,
        mut balance: Balance<B_TOKEN>,
        ts_ms: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Option<TypusBidReceipt>, Option<Balance<B_TOKEN>>, vector<u64>) {
        abort 0
    }
}