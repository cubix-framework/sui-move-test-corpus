module bucket_protocol::math {

    const U256_MAX: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    const EDividedByZero: u64 = 0;
    const ECalculationOverflow: u64 = 1;

    public fun mul_div(number: u64, numerator: u64, denominator: u64): u64 {
        assert!(denominator > 0, EDividedByZero);
        ((
            (number as u128) * (numerator as u128) / (denominator as u128)
        ) as u64)
    }

    public fun mul_div_u128(number: u64, numerator: u64, denominator: u64): u64 {
        assert!(denominator > 0, EDividedByZero);
        ((
            (number as u128) * (numerator as u128) / (denominator as u128)
        ) as u64)
    }

    // a * b / c
    public fun mul_factor_u256(number: u256, numerator: u256, denominator: u256): u256 {
        assert!(denominator > 0, EDividedByZero);
        
        let (number , numerator) = if (number >= numerator) {
            (number, numerator)
        } else {
            (numerator, number)
        };

        if (!is_safe_mul(number, numerator)) {
            // formula: ((a / c) * b) + (((a % c) * b) / c)
            checked_mul((number / denominator), numerator) + 
            (checked_mul((number % denominator), numerator) / denominator)
        } else { // round down
            number * numerator / denominator
        }
    }

    // check overflow
    public fun checked_mul(x: u256, y: u256): u256 {
        assert!(is_safe_mul(x, y), ECalculationOverflow);
        x * y
    }

    // check overflow, return true if x * y < U256_MAX
    public fun is_safe_mul(x: u256, y: u256): bool {
        (U256_MAX / x >= y)
    }

}