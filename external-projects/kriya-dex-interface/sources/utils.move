module kriya::utils {
    /// The integer scaling setting for fees calculation.
    const FEE_SCALING: u128 = 1000000;
    /// We take 10^8 as we expect most of the coins to have 6-8 decimals.
    const ONE_E_8: u128 = 100000000;

    /// Get output price for uncorrelated curve x*y = k
    public fun get_input_price_uncorrelated(
        input_amount: u64, 
        input_reserve: u64, 
        output_reserve: u64, 
        fee_percent: u64): u64 {
        abort 0
    }

    public fun get_input_price_stable(
        input_amount: u64, 
        input_reserve: u64, 
        output_reserve: u64, 
        fee_percent: u64,
        input_scale: u64,
        output_scale: u64
    ): u64{
        abort 0
    }

    /// Get LP value for stable curve: x^3*y + x*y^3
    /// * `x_coin` - reserves of coin X.
    /// * `x_scale` - 10 pow X coin decimals amount.
    /// * `y_coin` - reserves of coin Y.
    /// * `y_scale` - 10 pow Y coin decimals amount.
    public fun lp_value(x_coin: u128, x_scale: u64, y_coin: u128, y_scale: u64): u256 {
        abort 0
    }
}