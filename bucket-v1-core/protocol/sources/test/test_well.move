#[test_only]
module bucket_protocol::test_well {
    use std::vector;
    use sui::balance;
    use sui::clock::{Self, Clock};
    use sui::sui::SUI;
    use sui::test_scenario;
    use sui::transfer;
    use bucket_framework::math::mul_factor;
    use bucket_protocol::well::{Self, StakedBKT};
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
    use bucket_protocol::bkt::{Self, BKT, BktTreasury};
    use bucket_protocol::constants;
    use bucket_protocol::test_utils::{setup_empty, dev, approx_equal, stake_randomly};

    #[test]
    fun test_claim_reward() {
        let scenario_val = setup_empty(800);
        let scenario = &mut scenario_val;

        let staker_count: u8 = 100;
        let stakers = stake_randomly<BUCK>(scenario, staker_count);
        let fee_amount = 2_500_000_000_000;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let well = buck::borrow_well_mut<BUCK>(&mut protocol);
            well::airdrop(well, balance::create_for_testing<BUCK>(10));
            well::collect_fee(well, balance::create_for_testing<BUCK>(fee_amount));
            test_scenario::return_shared(protocol);
        };

        let idx: u8 = 0;
        let total_claimed_amount = 0;
        while (idx < staker_count) {
            let staker = *vector::borrow(&stakers, (idx as u64));
            test_scenario::next_tx(scenario, staker);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let well = buck::borrow_well_mut<BUCK>(&mut protocol);
                let st_bkt = test_scenario::take_from_sender<StakedBKT<BUCK>>(scenario);
                let well_pool_balance = well::get_well_pool_balance(well);
                assert!(well_pool_balance == fee_amount * 99 / 100 + 10 - total_claimed_amount, 0);
                let well_total_weight = well::get_well_total_weight(well);
                let token_weight = well::get_token_stake_weight(&st_bkt);
                let expected_reward_amount = mul_factor(fee_amount * 99 / 100, token_weight, well_total_weight);
                // std::debug::print(&idx);
                total_claimed_amount = total_claimed_amount + well::get_reward_amount(well, &st_bkt);
                // std::debug::print(&total_claimed_amount);
                // std::debug::print(&well::get_reward_amount(well, &st_bkt));
                // std::debug::print(&expected_reward_amount);
                assert!(approx_equal(well::get_reward_amount(well, &st_bkt), expected_reward_amount, 1), 0);
                let reward = well::claim(well, &mut st_bkt);
                assert!(approx_equal(balance::value(&reward), expected_reward_amount, 1), 0);
                assert!(well::get_reward_amount(well, &st_bkt) == 0, 0);
                balance::destroy_for_testing(reward);
                test_scenario::return_shared(protocol);
                test_scenario::return_to_sender(scenario, st_bkt);
            };
            idx = idx + 1;
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = well::EStillLocked)]
    fun test_failed_unstake_before_locked() {
        let scenario_val = setup_empty(800);
        let scenario = &mut scenario_val;
        let stakers = stake_randomly<SUI>(scenario, 1);
        let staker = *vector::borrow(&stakers, 0);

        test_scenario::next_tx(scenario, staker);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let well = buck::borrow_well_mut<SUI>(&mut protocol);
            let st_bkt = test_scenario::take_from_sender<StakedBKT<SUI>>(scenario);
            let lock_until = well::get_token_lock_until(&st_bkt);
            clock::set_for_testing(&mut clock, lock_until - 1);
            let (bkt_return, usdt_reward) = well::unstake(&clock, well, st_bkt);
            balance::destroy_for_testing(bkt_return);
            balance::destroy_for_testing(usdt_reward);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = well::ENotLocked)]
    fun test_failed_force_unstake_after_locked() {
        let scenario_val = setup_empty(800);
        let scenario = &mut scenario_val;
        let stakers = stake_randomly<SUI>(scenario, 2);
        let staker = *vector::borrow(&stakers, 1);

        test_scenario::next_tx(scenario, staker);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let well = buck::borrow_well_mut<SUI>(&mut protocol);
            let st_bkt = test_scenario::take_from_sender<StakedBKT<SUI>>(scenario);
            let lock_until = well::get_token_lock_until(&st_bkt);
            clock::set_for_testing(&mut clock, lock_until + 1);
            let (bkt_return, usdt_reward) = well::force_unstake(&clock, well, &mut bkt_treasury, st_bkt);
            balance::destroy_for_testing(bkt_return);
            balance::destroy_for_testing(usdt_reward);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_treasury);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = well::EInvalidLockTime)]
    fun test_lock_time_too_small() {
        let scenario_val = setup_empty(800);
        let scenario = &mut scenario_val;
        let staker = @0xcafe;
        test_scenario::next_tx(scenario, staker);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let well = buck::borrow_well_mut<BUCK>(&mut protocol);
            let st_bkt = well::stake(&clock, well, balance::create_for_testing<BKT>(1000), constants::min_lock_time() - 1, test_scenario::ctx(scenario));
            transfer::public_transfer(st_bkt, staker);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = well::EInvalidLockTime)]
    fun test_lock_time_too_large() {
        let scenario_val = setup_empty(800);
        let scenario = &mut scenario_val;
        let staker = @0xde11;
        test_scenario::next_tx(scenario, staker);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let well = buck::borrow_well_mut<SUI>(&mut protocol);
            let st_bkt = well::stake(&clock, well, balance::create_for_testing<BKT>(1000), constants::max_lock_time() + 1, test_scenario::ctx(scenario));
            transfer::public_transfer(st_bkt, staker);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = well::EStakeAmountTooSmall)]
    fun test_zero_stake_amount() {
        let scenario_val = setup_empty(800);
        let scenario = &mut scenario_val;
        let staker = @0xabcd;
        test_scenario::next_tx(scenario, staker);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let well = buck::borrow_well_mut<SUI>(&mut protocol);
            let st_bkt = well::stake(&clock, well, balance::create_for_testing<BKT>(0), constants::max_lock_time(), test_scenario::ctx(scenario));
            transfer::public_transfer(st_bkt, staker);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unstake() {
        let scenario_val = setup_empty(800);
        let scenario = &mut scenario_val;
        let staker_count: u8 = 80;
        let stakers = stake_randomly<SUI>(scenario, 80);
    
        let half_lock_time_range = (constants::min_lock_time() + constants::max_lock_time()) / 2;
        test_scenario::next_tx(scenario, dev());
        let init_eco_balance = {
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let eco_balance = bkt::get_eco_part_balance(&bkt_treasury);
            clock::increment_for_testing(&mut clock, half_lock_time_range);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_treasury);
            eco_balance
        };

        let cumulative_penalty_amount = 0;
        let idx: u8 = 0;
        while (idx < staker_count) {
            let staker = *vector::borrow(&stakers, (idx as u64));
            test_scenario::next_tx(scenario, staker);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let well = buck::borrow_well_mut<SUI>(&mut protocol);
                let clock = test_scenario::take_shared<Clock>(scenario);
                let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
                let current_time = clock::timestamp_ms(&clock);
                let st_bkt = test_scenario::take_from_sender<StakedBKT<SUI>>(scenario);
                if (current_time >= well::get_token_lock_until(&st_bkt)) {
                    let stake_amount = well::get_token_stake_amount(&st_bkt);
                    let (bkt_return, reward) = well::unstake(&clock, well, st_bkt);
                    assert!(balance::value(&bkt_return) == stake_amount, 0);
                    balance::destroy_for_testing(bkt_return);
                    balance::destroy_zero(reward);
                } else {
                    let penalty_amount = well::get_token_penalty_amount(&st_bkt, current_time);
                    let stake_amount = well::get_token_stake_amount(&st_bkt);
                    let (bkt_return, reward) = well::force_unstake(&clock, well, &mut bkt_treasury, st_bkt);
                    assert!(balance::value(&bkt_return) == stake_amount - penalty_amount, 0);
                    balance::destroy_for_testing(bkt_return);
                    balance::destroy_zero(reward);
                    cumulative_penalty_amount = cumulative_penalty_amount + penalty_amount;
                    assert!(init_eco_balance + cumulative_penalty_amount == bkt::get_eco_part_balance(&bkt_treasury), 0);
                };
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(clock);
                test_scenario::return_shared(bkt_treasury);
            };
            idx = idx + 1;
        };
        test_scenario::end(scenario_val);
    }
}