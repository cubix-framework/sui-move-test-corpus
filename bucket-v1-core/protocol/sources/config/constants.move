module bucket_protocol::constants {
    // Constant
    const LIQUIDATION_REBATE: u64 = 5_000; // 0.5%
    const LIQUIDATION_FEE: u64 = 20_000; // 2%
    const FEE_PRECISION: u64 = 1_000_000;
    const FLASH_LOAN_FEE: u64 = 500; // 0.05% fee
    const MINUTE_DECAY_FACTOR: u64 = 999037758833783500;
    const DECAY_FACTOR_PRECISION: u64 = 1_000_000_000_000_000_000; // 1e18
    const BUCK_DECIMAL: u8 = 9;
    const DECIMAL_FACTOR: u64 = 1_000_000_000; // 1e9
    const MAX_U64: u64 = 0xffffffffffffffff;
    const P_INITIAL_VALUE: u64 = 1_000_000_000_000_000_000; // 1e18
    const SCALE_FACTOR: u64 = 1_000_000_000; // 1e9
    const DISTRIBUTION_PRECISION: u128 = 0x10000000000000000;
    const MAX_LOCK_TIME: u64 = 31104000000; // ms of 360 days
    const MIN_LOCK_TIME: u64 = 2592000000; // ms of 30 days
    const MIN_FEE: u64 = 5_000; // 0.5%
    const MAX_FEE: u64 = 50_000; // 5%
    const INTEREST_PRECISION: u256 = 1_000_000_000_000_000_000_000_000_000; // 1e27
    const MS_IN_YEAR: u256 = 31536000000; // ms of 365 days


    public fun fee_precision(): u64 { FEE_PRECISION }

    public fun liquidation_rebate(): u64 { LIQUIDATION_REBATE }

    public fun flash_loan_fee(): u64 { FLASH_LOAN_FEE }

    public fun minute_decay_factor(): u64 { MINUTE_DECAY_FACTOR }

    public fun decay_factor_precision(): u64 { DECAY_FACTOR_PRECISION }

    public fun buck_decimal(): u8 { BUCK_DECIMAL }

    public fun decimal_factor(): u64 { DECIMAL_FACTOR }

    public fun max_u64(): u64 { MAX_U64 }

    public fun p_initial_value(): u64 { P_INITIAL_VALUE }

    public fun scale_factor(): u64 { SCALE_FACTOR }

    public fun distribution_precision(): u128 { DISTRIBUTION_PRECISION }

    public fun max_lock_time(): u64 { MAX_LOCK_TIME }   

    public fun min_lock_time(): u64 { MIN_LOCK_TIME }

    public fun min_fee(): u64 { MIN_FEE }

    public fun max_fee(): u64 { MAX_FEE }

    public fun interest_precision(): u256 { INTEREST_PRECISION }

    public fun ms_in_year(): u256 { MS_IN_YEAR }

    public fun liquidation_fee(): u64 { LIQUIDATION_FEE }
}