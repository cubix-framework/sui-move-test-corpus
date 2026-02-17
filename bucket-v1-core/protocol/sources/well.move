module bucket_protocol::well {

    use std::ascii::{Self, String};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::package;

    use bucket_framework::math::{mul_factor, mul_factor_u128};
    use bucket_protocol::bkt::{Self, BKT, BktTreasury, BktAdminCap};
    use bucket_protocol::constants::{min_lock_time, max_lock_time, distribution_precision};
    use bucket_protocol::well_events as events;

    friend bucket_protocol::buck;

    const EStillLocked: u64 = 0;
    const ENotLocked: u64 = 1;
    const EInvalidLockTime: u64 = 2;
    const EStakeAmountTooSmall: u64 = 3;

    struct Well<phantom T> has store, key {
        id: UID,
        shared_pool: Balance<T>,
        reserve: Balance<T>,
        staked: Balance<BKT>,
        total_weight: u64,
        current_s: u128,
    }

    struct StakedBKT<phantom T> has store, key {
        id: UID,
        stake_amount: u64,
        start_s: u128,
        stake_weight: u64,
        lock_until: u64,
    }

    struct WELL has drop {}

    fun init(otw: WELL, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    public(friend) fun new<T>(ctx: &mut TxContext): Well<T> {
        Well {
            id: object::new(ctx),
            shared_pool: balance::zero(),
            reserve: balance::zero(),
            staked: balance::zero(),
            total_weight: 0,
            current_s: 0,
        }
    }

    public fun collect_fee<T>(well: &mut Well<T>, fee: Balance<T>) {
        let fee_amount = balance::value(&fee);
        events::emit_collect_fee<T>(fee_amount);
        if (well.total_weight > 0 && fee_amount >= 100) {
            let fee_into_reserve = balance::split(&mut fee, fee_amount / 100);
            balance::join(&mut well.reserve, fee_into_reserve);
            let fee_amount = balance::value(&fee);
            balance::join(&mut well.shared_pool, fee);
            well.current_s = well.current_s + mul_factor_u128((fee_amount as u128), distribution_precision(), (well.total_weight as u128));
        } else {
            balance::join(&mut well.reserve, fee);
        }
    }

    public fun collect_fee_from<T>(well: &mut Well<T>, fee: Balance<T>, from: String) {
        events::emit_collect_fee_from<T>(&fee, ascii::into_bytes(from));
        collect_fee(well, fee);
    }

    public fun airdrop<T>(well: &mut Well<T>, drop: Balance<T>) {
        balance::join(&mut well.shared_pool, drop);
    }

    public fun stake<T>(
        clock: &Clock,
        well: &mut Well<T>,
        bkt_input: Balance<BKT>,
        lock_time: u64,
        ctx: &mut TxContext,
    ): StakedBKT<T> {
        let stake_amount = balance::value(&bkt_input);
        balance::join(&mut well.staked, bkt_input);
        let stake_weight = compute_weight(stake_amount, lock_time);
        well.total_weight = well.total_weight + stake_weight;

        events::emit_stake<T>(stake_amount, stake_weight, lock_time);

        StakedBKT {
            id: object::new(ctx),
            stake_amount,
            start_s: well.current_s,
            stake_weight,
            lock_until: clock::timestamp_ms(clock) + lock_time,
        }
    }

    public fun unstake<T>(
        clock: &Clock,
        well: &mut Well<T>,
        st_bkt: StakedBKT<T>,
    ): (Balance<BKT>, Balance<T>) {
        let reward_amount = get_reward_amount(well, &st_bkt);
        let StakedBKT { id, stake_amount, start_s: _, stake_weight, lock_until } = st_bkt;
        assert!(clock::timestamp_ms(clock) >= lock_until, EStillLocked);
        object::delete(id);
        well.total_weight = well.total_weight - stake_weight;
        events::emit_unstake<T>(stake_amount, stake_weight, reward_amount);
        (
            balance::split(&mut well.staked, stake_amount),
            balance::split(&mut well.shared_pool, reward_amount),
        )
    }

    public fun force_unstake<T>(
        clock: &Clock,
        well: &mut Well<T>,
        bkt_treasury: &mut BktTreasury,
        st_bkt: StakedBKT<T>,
    ): (Balance<BKT>, Balance<T>) {
        let reward_amount = get_reward_amount(well, &st_bkt);
        let current_time = clock::timestamp_ms(clock);
        let penalty_amount = get_token_penalty_amount(&st_bkt, current_time);
        let StakedBKT { id, stake_amount, start_s: _, stake_weight, lock_until } = st_bkt;
        assert!(current_time < lock_until, ENotLocked);
        object::delete(id);
        events::emit_penalty<T>(penalty_amount);
        let penalty = balance::split(&mut well.staked, penalty_amount);
        bkt::collect_bkt(bkt_treasury, penalty);

        let remaining_amount = stake_amount - penalty_amount;
        well.total_weight = well.total_weight - stake_weight;
        events::emit_unstake<T>(stake_amount, stake_weight, reward_amount);
        (
            balance::split(&mut well.staked, remaining_amount),
            balance::split(&mut well.shared_pool, reward_amount),
        )
    }

    public fun claim<T>(well: &mut Well<T>, st_bkt: &mut StakedBKT<T>): Balance<T> {
        let reward_amount = (mul_factor_u128(
            (st_bkt.stake_weight as u128),
            well.current_s - st_bkt.start_s,
            distribution_precision()
            ) as u64);
        events::emit_claim<T>(reward_amount);
        st_bkt.start_s = well.current_s;
        balance::split(&mut well.shared_pool, reward_amount)
    }

    public fun get_well_pool_balance<T>(well: &Well<T>): u64 {
        balance::value(&well.shared_pool)
    }

    public fun get_well_staked_balance<T>(well: &Well<T>): u64 {
        balance::value(&well.staked)
    }

    public fun get_well_total_weight<T>(well: &Well<T>): u64 {
        well.total_weight
    }

    public fun get_well_reserve_balance<T>(well: &Well<T>): u64 {
        balance::value(&well.reserve)
    }

    public fun get_token_stake_amount<T>(st_bkt: &StakedBKT<T>): u64 {
        st_bkt.stake_amount
    }

    public fun get_token_stake_weight<T>(st_bkt: &StakedBKT<T>): u64 {
        st_bkt.stake_weight
    }

    public fun get_token_lock_until<T>(st_bkt: &StakedBKT<T>): u64 {
        st_bkt.lock_until
    }

    public fun get_token_penalty_amount<T>(st_bkt: &StakedBKT<T>, current_time: u64): u64 {
        if (current_time >= st_bkt.lock_until) {
            0
        } else {
            let penalty_weight = mul_factor(st_bkt.stake_amount, st_bkt.lock_until - current_time, max_lock_time());
            mul_factor(st_bkt.stake_amount, penalty_weight, st_bkt.stake_weight)
        }        
    }

    public fun get_reward_amount<T>(well: &Well<T>, st_bkt: &StakedBKT<T>): u64 {
        (mul_factor_u128((st_bkt.stake_weight as u128), well.current_s - st_bkt.start_s, distribution_precision()) as u64)
    }

    public fun withdraw_reserve<T>(_ : &BktAdminCap, well: &mut Well<T>): Balance<T> {
        let reserve_amount = balance::value(&well.reserve);
        balance::split(&mut well.reserve, reserve_amount)
    }

    fun compute_weight(stake_amount: u64, lock_time: u64): u64 {
        assert!(lock_time >= min_lock_time() && lock_time <= max_lock_time(), EInvalidLockTime);
        let weight = mul_factor(stake_amount, lock_time, max_lock_time());
        assert!(weight > 0, EStakeAmountTooSmall);
        weight
    }

    #[test_only]
    public fun destroy_for_testing<T>(st_bkt: StakedBKT<T>) {
        let StakedBKT { id, stake_amount: _, start_s: _, stake_weight: _, lock_until: _ } = st_bkt;
        object::delete(id);
    }

    #[test]
    fun test_publisher() {
        use sui::test_scenario;
        use sui::test_utils;
        use sui::package::{Self, Publisher};

        let dev = @0x123;

        let scenario_val = test_scenario::begin(dev);
        let scenario = &mut scenario_val;
        {
            init(test_utils::create_one_time_witness<WELL>(),test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, dev);
        {
            let publisher = test_scenario::take_from_sender<Publisher>(scenario);
            assert!(package::from_package<WELL>(&publisher), 0);
            assert!(package::from_module<WELL>(&publisher), 0);
            test_scenario::return_to_sender(scenario, publisher);
        };

        test_scenario::end(scenario_val);
    }
}
