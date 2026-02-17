module bucket_protocol::tank_events {

    use std::ascii::String;
    use sui::event;
    use std::type_name;

    friend bucket_protocol::tank;

    struct Deposite has copy, drop {
        tank_type: String,
        buck_amount: u64,
    }

    struct Withdraw has copy, drop {
        tank_type: String,
        buck_amount: u64,
        collateral_amount: u64,
        bkt_amount: u64,
    }

    struct Absorb has copy, drop {
        tank_type: String,
        buck_amount: u64,
        collateral_amount: u64,
    }

    struct TankUpdate has copy, drop {
        tank_type: String,
        current_epoch: u64,
        current_scale: u64,
        current_p: u64,
    }

    struct CollectBKT has copy, drop {
        tank_type: String,
        bkt_amount: u64,
    }

    public(friend) fun emit_deposit<T>(buck_amount: u64) {
        let tank_type = type_name::into_string(type_name::get<T>());
        event::emit(Deposite { tank_type, buck_amount});
    }

    public(friend) fun emit_withdraw<T>(buck_amount: u64, collateral_amount: u64, bkt_amount: u64) {
        let tank_type = type_name::into_string(type_name::get<T>());
        event::emit(Withdraw { tank_type, buck_amount, collateral_amount, bkt_amount});
    }

    public(friend) fun emit_absorb<T>(buck_amount: u64, collateral_amount: u64) {
        let tank_type = type_name::into_string(type_name::get<T>());
        event::emit(Absorb { tank_type, buck_amount, collateral_amount });
    }

    public(friend) fun emit_tank_update<T>(current_epoch: u64, current_scale: u64, current_p: u64) {
        let tank_type = type_name::into_string(type_name::get<T>());
        event::emit(TankUpdate { tank_type, current_epoch, current_scale, current_p });
    }

    public(friend) fun emit_collect_bkt<T>(bkt_amount: u64) {
        let tank_type = type_name::into_string(type_name::get<T>());
        event::emit(CollectBKT { tank_type, bkt_amount });
    }
}