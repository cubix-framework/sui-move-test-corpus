module bucket_protocol::bucket_events {

    use std::ascii::String;
    use sui::object::{Self, ID};
    use sui::event;
    use std::type_name;
    use bucket_protocol::bottle::{Self, Bottle};

    friend bucket_protocol::bucket;

    struct BottleCreated has copy, drop {
        collateral_type: String,
        debtor: address,
        bottle_id: ID,
        collateral_amount: u64,
        buck_amount: u64,
    }

    struct BottleUpdated has copy, drop {
        collateral_type: String,
        debtor: address,
        bottle_id: ID,
        collateral_amount: u64,
        buck_amount: u64,
    }

    struct BottleDestroyed has copy, drop {
        collateral_type: String,
        debtor: address,
        bottle_id: ID,
    }

    struct SurplusBottleGenerated has copy, drop {
        collateral_type: String,
        debtor: address,
        bottle_id: ID,
        collateral_amount: u64,
    }

    struct SurplusBottleWithdrawal has copy, drop {
        collateral_type: String,
        debtor: address,
        bottle_id: ID,
    }

    struct Redeem has copy, drop {
        collateral_type: String,
        input_buck_amount: u64,
        output_collateral_amount: u64,
    }

    struct FeeRateChanged has copy, drop {
        collateral_type: String,
        base_fee_rate: u64,
    }

    struct Redistribution has copy, drop {
        collateral_type: String,
    }

    public(friend) fun emit_bottle_created<T>(debtor: address, bottle: &Bottle) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        let bottle_id = *object::borrow_id(bottle);
        let (collateral_amount, buck_amount) = bottle::get_bottle_raw_info(bottle);
        event::emit(BottleCreated { collateral_type, debtor, bottle_id, collateral_amount, buck_amount });
    }

    public(friend) fun emit_bottle_updated<T>(debtor: address, bottle: &Bottle) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        let bottle_id = *object::borrow_id(bottle);
        let (collateral_amount, buck_amount) = bottle::get_bottle_raw_info(bottle);
        event::emit(BottleUpdated { collateral_type, debtor, bottle_id, collateral_amount, buck_amount });
    }
    
    public(friend) fun emit_bottle_destroyed<T>(debtor: address, bottle: &Bottle) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        let bottle_id = *object::borrow_id(bottle);
        event::emit(BottleDestroyed { collateral_type, debtor, bottle_id });
    }

    public(friend) fun emit_surplus_bottle_generated<T>(debtor: address, bottle: &Bottle) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        let bottle_id = *object::borrow_id(bottle);
        let (collateral_amount, _) = bottle::get_bottle_raw_info(bottle);
        event::emit(SurplusBottleGenerated { collateral_type, debtor, bottle_id, collateral_amount });
    }

    public(friend) fun emit_surplus_bottle_withdrawal<T>(debtor: address, bottle: &Bottle) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        let bottle_id = *object::borrow_id(bottle);
        event::emit(SurplusBottleWithdrawal { collateral_type, debtor, bottle_id });
    }

    public(friend) fun emit_redeem<T>(input_buck_amount: u64, output_collateral_amount: u64) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        event::emit(Redeem { collateral_type, input_buck_amount, output_collateral_amount });
    }

    public(friend) fun emit_fee_rate_changed<T>(base_fee_rate: u64) {
        let collateral_type = type_name::into_string(type_name::get<T>());
        event::emit(FeeRateChanged { collateral_type, base_fee_rate });
    }

    public(friend) fun emit_redistribution<T>() {
        let collateral_type = type_name::into_string(type_name::get<T>());
        event::emit(Redistribution { collateral_type });
    }
}