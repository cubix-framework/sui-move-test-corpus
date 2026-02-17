// Peg Stability Module (PSM) in Bucket
module bucket_protocol::reservoir {

    use std::type_name::{Self, TypeName};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::TxContext;
    use sui::dynamic_field as df;
    use sui::vec_map::{Self, VecMap};
    use bucket_protocol::reservoir_events as events;
    use bucket_protocol::math::mul_div;

    friend bucket_protocol::buck;

    // --------------- Constants ---------------
    
    const CONVERSION_RATE_PRECISION: u64 = 1_000_000_000;

    // --------------- Errors ---------------

    const EReservoirNotEnough: u64 = 0;

    // --------------- Objects ---------------

    struct Reservoir<phantom T> has key, store {
        id: UID,
        // settings
        conversion_rate: u64,
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
        // states
        pool: Balance<T>,
        buck_minted_amount: u64,
    }

    struct FeeConfigKey has copy, drop, store {}

    struct FeeConfig has copy, drop, store {
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
    }

    // --------------- Friend Functions ---------------

    public(friend) fun new<T>(
        conversion_rate: u64,
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
        ctx: &mut TxContext,
    ): Reservoir<T> {
        Reservoir<T> {
            id: object::new(ctx),
            conversion_rate,
            charge_fee_rate,
            discharge_fee_rate,
            pool: balance::zero(),
            buck_minted_amount: 0,
        }
    }

    public(friend) fun handle_charge<T>(
        reservoir: &mut Reservoir<T>,
        collateral: Balance<T>,
    ): u64 {
        let inflow_amount = balance::value(&collateral);
        let buck_amount = mul_div(
            inflow_amount,
            reservoir.conversion_rate,
            CONVERSION_RATE_PRECISION,
        );
        events::emit_charge_reservoir<T>(inflow_amount, buck_amount);
        balance::join(&mut reservoir.pool, collateral);
        reservoir.buck_minted_amount = reservoir.buck_minted_amount + buck_amount;
        buck_amount
    }

    public(friend) fun handle_discharge<T>(
        reservoir: &mut Reservoir<T>,
        buck_amount: u64,
    ): Balance<T> {
        let outflow_amount = mul_div(
            buck_amount,
            CONVERSION_RATE_PRECISION,
            reservoir.conversion_rate,
        );
        assert!(outflow_amount <= pool_balance(reservoir), EReservoirNotEnough);
        events::emit_discharge_reservoir<T>(outflow_amount, buck_amount);
        reservoir.buck_minted_amount = reservoir.buck_minted_amount - buck_amount;
        balance::split(&mut reservoir.pool, outflow_amount)
    }

    public(friend) fun update_fee_rate<T>(
        reservoir: &mut Reservoir<T>,
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
    ) {
        reservoir.charge_fee_rate = charge_fee_rate;
        reservoir.discharge_fee_rate = discharge_fee_rate;
    }

    public(friend) fun set_fee_config<T, P: drop>(
        reservoir: &mut Reservoir<T>,
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
    ) {
        let key = FeeConfigKey {};
        let partner_name = type_name::get<P>();
        if (df::exists_with_type<FeeConfigKey, VecMap<TypeName, FeeConfig>>(&reservoir.id, key)) {
            let config_map = df::borrow_mut<FeeConfigKey, VecMap<TypeName, FeeConfig>>(&mut reservoir.id, key);
            if (vec_map::contains(config_map, &partner_name)) {
                let config = vec_map::get_mut(config_map, &partner_name);
                config.charge_fee_rate = charge_fee_rate;
                config.discharge_fee_rate = discharge_fee_rate;
            } else {
                vec_map::insert(config_map, partner_name, FeeConfig {
                    charge_fee_rate, discharge_fee_rate,
                });
            };
        } else {
            let config_map = vec_map::empty();
            vec_map::insert(&mut config_map, partner_name, FeeConfig {
                charge_fee_rate, discharge_fee_rate,
            });
            df::add(&mut reservoir.id, key, config_map);
        };
    }

    // --------------- Getter Functions ---------------

    public fun charge_fee_rate<T>(reservoir: &Reservoir<T>): u64 {
        reservoir.charge_fee_rate
    }

    public fun discharge_fee_rate<T>(reservoir: &Reservoir<T>): u64 {
        reservoir.discharge_fee_rate
    }

    public fun conversion_rate<T>(reservoir: &Reservoir<T>): u64 {
        reservoir.conversion_rate
    }

    public fun pool_balance<T>(reservoir: &Reservoir<T>): u64 {
        balance::value(&reservoir.pool)
    }

    public fun is_partner<T, P: drop>(reservoir: &Reservoir<T>): bool {
        let key = FeeConfigKey {};
        let partner_name = type_name::get<P>();
        df::exists_with_type<FeeConfigKey, VecMap<TypeName, FeeConfig>>(&reservoir.id, key)
        &&
        vec_map::contains(
            df::borrow<FeeConfigKey, VecMap<TypeName, FeeConfig>>(&reservoir.id, key),
            &partner_name
        )
    }

    public fun charge_fee_rate_for_partner<T, P: drop>(reservoir: &Reservoir<T>): u64 {
        if (is_partner<T, P>(reservoir)) {
            vec_map::get(
                df::borrow<FeeConfigKey, VecMap<TypeName, FeeConfig>>(
                    &reservoir.id, FeeConfigKey {}
                ),
                &type_name::get<P>()
            ).charge_fee_rate
        } else {
            charge_fee_rate(reservoir)
        }
    }

    public fun discharge_fee_rate_for_partner<T, P: drop>(reservoir: &Reservoir<T>): u64 {
        if (is_partner<T, P>(reservoir)) {
            vec_map::get(
                df::borrow<FeeConfigKey, VecMap<TypeName, FeeConfig>>(
                    &reservoir.id, FeeConfigKey {}
                ),
                &type_name::get<P>()
            ).discharge_fee_rate
        } else {
            discharge_fee_rate(reservoir)
        }
    }
}