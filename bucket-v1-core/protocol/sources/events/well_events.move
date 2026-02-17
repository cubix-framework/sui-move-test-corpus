module bucket_protocol::well_events {
    
    use std::ascii::String;
    use sui::event;
    use sui::balance::{Self, Balance};
    use std::type_name;

    friend bucket_protocol::well;
    friend bucket_protocol::buck;

    struct CollectFee has copy, drop {
        well_type: String,
        fee_amount: u64,   
    }

    struct Stake has copy, drop {
        well_type: String,
        stake_amount: u64,
        stake_weight: u64,
        lock_time: u64,
    }

    struct Unstake has copy, drop {
        well_type: String,
        unstake_amount: u64,
        unstake_weigth: u64,
        reward_amount: u64,
    }

    struct Claim has copy, drop {
        well_type: String,
        reward_amount: u64,
    }

    struct Penalty has copy, drop {
        well_type: String,
        penalty_amount: u64,
    }

    public(friend) fun emit_collect_fee<T>(fee_amount: u64) {
        let well_type = type_name::into_string(type_name::get<T>());
        event::emit(CollectFee { well_type, fee_amount });
    }

    public(friend) fun emit_stake<T>(stake_amount: u64, stake_weight: u64, lock_time: u64) {
        let well_type = type_name::into_string(type_name::get<T>());
        event::emit(Stake { well_type, stake_amount, stake_weight, lock_time});
    }

    public(friend) fun emit_unstake<T>(unstake_amount: u64, unstake_weigth: u64, reward_amount: u64) {
        let well_type = type_name::into_string(type_name::get<T>());
        event::emit(Unstake { well_type, unstake_amount, unstake_weigth, reward_amount });
    }

    public(friend) fun emit_claim<T>(reward_amount: u64) {
        let well_type = type_name::into_string(type_name::get<T>());
        event::emit(Claim { well_type, reward_amount });
    }

    public(friend) fun emit_penalty<T>(penalty_amount: u64) {
        let well_type = type_name::into_string(type_name::get<T>());
        event::emit(Penalty { well_type, penalty_amount });
    }

    struct CollectFeeFrom has copy, drop {
        well_type: String,
        fee_amount: u64,
        from: String,
    }

    public(friend) fun emit_collect_fee_from<T>(
        fee: &Balance<T>,
        from: vector<u8>,
    ) {
        let well_type = type_name::into_string(type_name::get<T>());
        let fee_amount = balance::value(fee);
        let from = std::string::to_ascii(std::string::utf8(from));
        event::emit(CollectFeeFrom { well_type, fee_amount, from });
    }
}