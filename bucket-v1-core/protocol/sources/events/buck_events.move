module bucket_protocol::buck_events {

    use std::ascii::{Self, String};
    use sui::event;
    use std::type_name;
    use sui::object::ID;
    use std::option::Option;

    friend bucket_protocol::buck;

    struct BuckMinted has copy, drop {
        collateral_type: String,
        buck_amount: u64,
    }

    struct BuckBurnt has copy, drop {
        collateral_type: String,
        buck_amount: u64,
    }

    struct CollateralIncreased has copy, drop {
        collateral_type: String,
        collateral_amount: u64,
    }

    struct CollateralDecreased has copy, drop {
        collateral_type: String,
        collateral_amount: u64,
    }

    struct FlashLoan has copy, drop {
        coin_type: String,
        amount: u64,
    }

    struct FlashMint has copy, drop {
        config_id: ID,
        mint_amount: u64,
        fee_amount: u64,
    }

    public(friend) fun emit_buck_minted<T>(buck_amount: u64) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        event::emit(BuckMinted { collateral_type, buck_amount });
    }

    public(friend) fun emit_buck_burnt<T>(buck_amount: u64) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        event::emit(BuckBurnt { collateral_type, buck_amount });
    }

    public(friend) fun emit_collateral_increased<T>(collateral_amount: u64) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        event::emit(CollateralIncreased { collateral_type, collateral_amount });
    }

    public(friend) fun emit_collateral_decreased<T>(collateral_amount: u64) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        event::emit(CollateralDecreased { collateral_type, collateral_amount });
    }

    public(friend) fun emit_flash_loan<T>(amount: u64) {
        let coin_type = type_name::into_string(type_name::get<T>());
        event::emit(FlashLoan { coin_type, amount });
    }

    public(friend) fun emit_flash_mint(
        config_id: ID,
        mint_amount: u64,
        fee_amount: u64,
    ) {
        event::emit(FlashMint {
            config_id, mint_amount, fee_amount,
        });
    }

    struct ParamUpdated<phantom ComponentType> has copy, drop {
        param_name: String,
        new_value: u64,
    }

    public(friend) fun emit_param_updated<C>(
        param_name: vector<u8>,
        new_value: u64,
    ) {
        let param_name = ascii::string(param_name);
        event::emit(ParamUpdated<C> { param_name, new_value });
    }

    struct Liquidation<phantom T> has copy, drop {
        price_n: u64,
        price_m: u64,
        coll_amount: u64,
        debt_amount: u64,
        tcr: Option<u64>,
        debtor: address,
    }

    public(friend) fun emit_liquidation<T>(
        price_n: u64,
        price_m: u64,
        coll_amount: u64,
        debt_amount: u64,
        tcr: Option<u64>,
        debtor: address,
    ) {
        event::emit(Liquidation<T> {
            price_n,
            price_m,
            coll_amount,
            debt_amount,
            tcr,
            debtor,
        });
    }
}