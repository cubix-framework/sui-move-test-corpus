#[test_only]
module bucket_protocol::test_redeem {

    use sui::balance;
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use std::option;
    use bucket_framework::math::mul_factor;
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::well;
    use bucket_protocol::bkt::BktAdminCap;
    use bucket_protocol::test_utils::{setup_randomly, approx_equal, dev};
    use bucket_oracle::bucket_oracle::{Self, BucketOracle};
    use bucket_protocol::constants;

    #[test]
    fun test_redeem() {

        let oracle_price: u64 = 2000;

        let (scenario_val, _) = setup_randomly(oracle_price, 50);
        let scenario = &mut scenario_val;

        let fee_precision = constants::fee_precision();
        let min_fee_rate = constants::min_fee();

        let init_buck_amount: u64;
        let sui_output_amount: u64;
        let fee_rate: u64;

        let redeemer = @0x222;
        test_scenario::next_tx(scenario, redeemer);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            clock::increment_for_testing(&mut clock, 86400000);
            bucket_oracle::update_price_for_testing<SUI>( &mut oracle, 4000);
            let (price, denominator) = bucket_oracle::get_price<SUI>(&oracle, &clock);
            
            let total_buck_amount = bucket::get_minted_buck_amount(buck::borrow_bucket<SUI>(&protocol));
            init_buck_amount = total_buck_amount;
            let buck_amount_for_redemption = total_buck_amount / 50;

            let buck_input = balance::create_for_testing<BUCK>(buck_amount_for_redemption);
            // std::debug::print(&buck_input);
            let sui_output = buck::redeem<SUI>(&mut protocol, &oracle, &clock, buck_input, option::none());
            // std::debug::print(&sui_output);
            sui_output_amount = balance::value(&sui_output);
            let sui_value = mul_factor(sui_output_amount, price, denominator);
            fee_rate = bucket::compute_base_rate(buck::borrow_bucket<SUI>(&protocol), clock::timestamp_ms(&clock));
            // std::debug::print(&fee_rate);
            assert!(fee_rate == 15000, 0);
            let buck_value_after_charging = mul_factor(buck_amount_for_redemption, fee_precision - fee_rate, fee_precision);
            // std::debug::print(&sui_value);
            // std::debug::print(&buck_value_after_charging);
            assert!(approx_equal(sui_value, buck_value_after_charging, 1), 0);
            balance::destroy_for_testing(sui_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<BktAdminCap>(scenario);
            
            let buck_well = buck::borrow_well_mut<BUCK>(&mut protocol);
            let buck_fee = well::withdraw_reserve<BUCK>(&admin_cap, buck_well);
            let buck_fee_amount = balance::value(&buck_fee);
            let expected_buck_fee_amount = mul_factor(init_buck_amount, min_fee_rate, fee_precision + min_fee_rate);
            // std::debug::print(&buck_fee_amount);
            // std::debug::print(&expected_buck_fee_amount);
            assert!(approx_equal(buck_fee_amount, expected_buck_fee_amount, 1), 0);
            balance::destroy_for_testing(buck_fee);

            let sui_well = buck::borrow_well_mut<SUI>(&mut protocol);
            let sui_fee = well::withdraw_reserve<SUI>(&admin_cap, sui_well);
            let sui_fee_amount = balance::value(&sui_fee);
            let expected_sui_fee_amount = mul_factor(sui_output_amount, fee_rate, fee_precision - fee_rate);
            // std::debug::print(&sui_fee_amount);
            // std::debug::print(&expected_sui_fee_amount);
            assert!(sui_fee_amount == expected_sui_fee_amount, 0);
            balance::destroy_for_testing(sui_fee);

            test_scenario::return_shared(protocol);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        let borrower = @0x111;
        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            clock::increment_for_testing(&mut clock, 43200000); // after 12 hrs
            bucket_oracle::update_price_for_testing<SUI>( &mut oracle, 3950);
        
            let sui_input_amount = 1000000000000000 / 3950 * 150 / 100;
            let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
            let buck_output_amount = 1000000000000;
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, option::none(), test_scenario::ctx(scenario));
            assert!(balance::value(&buck_output) == buck_output_amount, 0);

            let expected_fee_rate = fee_rate / 2;
            fee_rate = bucket::compute_base_rate(buck::borrow_bucket<SUI>(&protocol), clock::timestamp_ms(&clock));
            // std::debug::print(&fee_rate);
            assert!(fee_rate == expected_fee_rate, 0);
            let buck_well_reserve_balance = well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol));
            let buck_fee_amount = mul_factor(buck_output_amount, fee_rate, fee_precision);
            // std::debug::print(&buck_well_reserve_balance);
            // std::debug::print(&buck_fee_amount);
            assert!(buck_well_reserve_balance == buck_fee_amount, 0);

            balance::destroy_for_testing(buck_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::ENotEnoughToRedeem)]
    fun test_not_enough_to_redeem() {
        use std::vector;
        let oracle_price: u64 = 1950;
        let borrower_count: u8 = 24;
        let (scenario_val, borrowers) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let redeemer = @0x4556789;
        let insertion_place = *vector::borrow(&borrowers, 12);
        test_scenario::next_tx(scenario, redeemer);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let total_buck_amount = bucket::get_minted_buck_amount(bucket);
            let redemption_amount = total_buck_amount + 1;
            let buck_input = balance::create_for_testing<BUCK>(redemption_amount);
            let sui_output = buck::redeem<SUI>(&mut protocol, &oracle, &clock, buck_input, std::option::some(insertion_place));
            balance::destroy_for_testing(sui_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }
}