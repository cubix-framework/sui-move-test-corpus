#[test_only]
module bucket_protocol::test_surplus_bottle {
    use std::vector;
    use sui::balance;
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use bucket_framework::math::mul_factor;
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::test_utils::{setup_customly, setup_randomly, dev, start_time};
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::constants;

    #[test]
    fun test_withdraw_surplus_bottle() {
        // use sui::clock;

        let oracle_price: u64 = 1_000;
        let collateral_amounts = vector<u64>[
            1_900_000_000_000,
            1_800_000_000_000,
            1_700_000_000_000,
            1_600_000_000_000,
            1_500_000_000_000,
            1_400_000_000_000,
            1_300_000_000_000,
            1_200_000_000_000,
            1_100_000_000_000,
            1_000_000_000_000,
        ];
        let debt_amounts = vector<u64>[
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
        ];
        let (scenario_val, borrowers) = setup_customly(oracle_price, collateral_amounts, debt_amounts);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::get_collateral_vault_balance(bucket) == 14_500_000_000_000, 0);
            assert!(bucket::get_minted_buck_amount(bucket) == mul_factor(5_000_000_000_000, constants::fee_precision() + constants::min_fee(), constants::fee_precision()), 0);
            assert!(bucket::get_bucket_size(bucket) == 10, 0);
            test_scenario::return_shared(protocol);
        };

        let redeemer = @0x123;
        let redeem_amount = 753_750_000_000;
        test_scenario::next_tx(scenario, redeemer);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);            
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(redeem_amount);
            let sui_output = buck::redeem<SUI>(&mut protocol, &oracle, &clock, buck_input, std::option::none());
            // let bucket = buck::borrow_bucket<SUI>(&protocol);
            // std::debug::print(&bucket::compute_base_rate_fee(bucket, clock::timestamp_ms(&clock)));
            // std::debug::print(&sui_output);
            assert!(balance::value(&sui_output) == mul_factor(redeem_amount, 1_000_000 - 80_000, 1_000_000), 0);
            balance::destroy_for_testing(sui_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        let borrower = @0x456;
        let buck_output_amount: u64 = 800_000_000_000;
        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);            
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::compute_base_rate(bucket, start_time()) == 80_000, 0);
            assert!(bucket::get_surplus_bottle_table_size(bucket) == 1, 0);
            assert!(bucket::get_bucket_size(bucket) == 9, 0);
            let sui_input_amount = buck_output_amount * 2;
            let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
            let insertion_place = *vector::borrow(&borrowers, 0);
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, std::option::some(insertion_place), test_scenario::ctx(scenario));
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);            
            let (_, buck_amount) = buck::get_bottle_info_by_debtor<SUI>(&protocol, borrower);
            assert!(buck_amount == buck_output_amount * 105 / 100, 0);
            test_scenario::return_shared(protocol);
        };

        let debtor = *vector::borrow(&borrowers, 9);
        test_scenario::next_tx(scenario, debtor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (collateral_amount, debt_amount) = bucket::get_surplus_bottle_info_by_debtor(bucket, debtor);
            let collateral_amount_only = bucket::get_surplus_collateral_amount(bucket, debtor);
            assert!(collateral_amount == collateral_amount_only, 0);
            assert!(debt_amount == 0, 0);
            let collateral_return = buck::withdraw_surplus_collateral<SUI>(&mut protocol, test_scenario::ctx(scenario));
            assert!(balance::value(&collateral_return) == collateral_amount, 0);
            balance::destroy_for_testing(collateral_return);
            test_scenario::return_shared(protocol);
        };

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::get_bucket_size(bucket) == 10, 0);
            assert!(bucket::get_surplus_bottle_table_size(bucket) == 0, 0);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_create_bottle_with_surplus() {
        // use sui::clock;

        let oracle_price: u64 = 1_000;
        let collateral_amounts = vector<u64>[
            1_900_000_000_000,
            1_800_000_000_000,
            1_700_000_000_000,
            1_600_000_000_000,
            1_500_000_000_000,
            1_400_000_000_000,
            1_300_000_000_000,
            1_200_000_000_000,
            1_100_000_000_000,
            1_000_000_000_000,
        ];
        let debt_amounts = vector<u64>[
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
            500_000_000_000,
        ];
        let (scenario_val, borrowers) = setup_customly(oracle_price, collateral_amounts, debt_amounts);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::get_collateral_vault_balance(bucket) == 14_500_000_000_000, 0);
            assert!(bucket::get_minted_buck_amount(bucket) == mul_factor(5_000_000_000_000, constants::fee_precision() + constants::min_fee(), constants::fee_precision()), 0);
            test_scenario::return_shared(protocol);
        };

        let redeemer = @0x123;
        let redeem_amount = 753_750_000_000;
        test_scenario::next_tx(scenario, redeemer);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);            
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(redeem_amount);
            let sui_output = buck::redeem<SUI>(&mut protocol, &oracle, &clock, buck_input, std::option::none());
            // let bucket = buck::borrow_bucket<SUI>(&protocol);
            // std::debug::print(&bucket::compute_base_rate_fee(bucket, clock::timestamp_ms(&clock)));
            // std::debug::print(&sui_output);
            assert!(balance::value(&sui_output) == mul_factor(redeem_amount, 1_000_000 - 80_000, 1_000_000), 0);
            balance::destroy_for_testing(sui_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        let borrower = @0x456;
        let buck_output_amount: u64 = 800_000_000_000;
        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);            
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::compute_base_rate(bucket, start_time()) == 80_000, 0);
            assert!(bucket::get_surplus_bottle_table_size(bucket) == 1, 0);
            let sui_input_amount = buck_output_amount * 2;
            let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);            
            let (_, buck_amount) = buck::get_bottle_info_by_debtor<SUI>(&protocol, borrower);
            assert!(buck_amount == buck_output_amount * 105 / 100, 0);
            test_scenario::return_shared(protocol);
        };

        let debtor = *vector::borrow(&borrowers, 9);
        test_scenario::next_tx(scenario, debtor);
        let (collateral_amount, sui_input_amount, buck_output_amount) = {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            clock::increment_for_testing(&mut clock, 525600001 * 60000);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let collateral_amount = bucket::get_surplus_collateral_amount(bucket, debtor);
            let sui_input_amount: u64 = 500_000_000_000;
            let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
            let buck_output_amount: u64 = 500_000_000_000;
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            (collateral_amount, sui_input_amount, buck_output_amount)
        };

        test_scenario::next_tx(scenario, debtor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let (sui_amount_after, buck_amount_after) = buck::get_bottle_info_by_debtor<SUI>(&protocol, debtor);
            assert!(sui_amount_after == collateral_amount + sui_input_amount, 0);
            assert!(buck_amount_after == buck_output_amount * 1005 / 1000, 0);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::get_surplus_bottle_table_size(bucket) == 0, 0);
            assert!(bucket::get_bucket_size(bucket) == 11, 0);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::ESurplusBottleNotFound)]
    fun test_no_surplus_bottle() {
        let oracle_price: u64 = 1123;
        let borrower_count: u8 = 12;
        let (scenario_val, borrowers) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let debtor = *vector::borrow(&borrowers, 3);
        test_scenario::next_tx(scenario, debtor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let sui_surplus = buck::withdraw_surplus_collateral<SUI>(&mut protocol, test_scenario::ctx(scenario));
            balance::destroy_for_testing(sui_surplus);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }
}