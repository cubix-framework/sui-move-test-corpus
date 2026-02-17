#[test_only]
module bucket_protocol::test_borrow {

    use std::vector;
    use sui::balance;
    use sui::test_scenario;
    // use sui::test_utils;
    use sui::sui::SUI;
    use sui::clock::Clock;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::bottle;
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::well;
    use bucket_protocol::bkt::BktAdminCap;
    use bucket_protocol::constants;
    use bucket_protocol::test_utils::{setup_randomly, setup_empty, setup_customly, dev, approx_equal};
    use bucket_framework::math::mul_factor;

    #[test]
    fun test_borrow_again() {
        let oracle_price: u64 = 1050;
        let borrower_count: u8 = 91;
        let (scenario_val, borrowers) = setup_randomly(oracle_price, borrower_count);
        assert!(vector::length(&borrowers) == (borrower_count as u64), 0);
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, dev());
        {
            // test_utils::print(b"---------- Bottle Table Result ----------");
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            bucket::check_bottle_order_in_bucket(bucket, false);
            assert!(bucket::get_bucket_size(bucket) == 91, 0);
            let total_buck_amount = bucket::get_minted_buck_amount(buck::borrow_bucket<SUI>(&protocol));
            let well_buck_amount = well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol));
            let expected_well_buck_amount = mul_factor(total_buck_amount, 5, 1005);
            // std::debug::print(&well_buck_amount);
            // std::debug::print(&expected_well_buck_amount);
            assert!(approx_equal(well_buck_amount, expected_well_buck_amount, 100), 0);
            let admin_cap = test_scenario::take_from_sender<BktAdminCap>(scenario);
            let withdrawal_fee = well::withdraw_reserve(&admin_cap, buck::borrow_well_mut<BUCK>(&mut protocol));
            assert!(balance::value(&withdrawal_fee) == well_buck_amount, 0);
            balance::destroy_for_testing(withdrawal_fee);
            
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        let debtor = *vector::borrow(&borrowers, 90);
        test_scenario::next_tx(scenario, debtor);
        let (sui_amount, buck_amount) = {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let (sui_amount, buck_amount) = buck::get_bottle_info_by_debtor<SUI>(&protocol, debtor); 
            let sui_input = balance::create_for_testing<SUI>(sui_amount);
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_amount, std::option::none(), test_scenario::ctx(scenario));
            assert!(balance::value(&buck_output) == buck_amount, 0); 
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            (sui_amount, buck_amount)
        };

        test_scenario::next_tx(scenario, debtor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let (sui_amount_after, buck_amount_after) = buck::get_bottle_info_by_debtor<SUI>(&protocol, debtor); 
            assert!(sui_amount_after == 2 * sui_amount, 0);
            // std::debug::print(&buck_amount_after);
            // std::debug::print(&(buck_amount + buck_amount * 1005 / 1000));
            assert!(approx_equal(buck_amount_after, buck_amount + buck_amount * 1005 / 1000, 1), 0);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::EBottleIsNotHealthy)]
    fun test_create_unhealty_bottle() {
        let oracle_price: u64 = 750;
        let borrower_count: u8 = 37;
        let (scenario_val, _) = setup_randomly(oracle_price, borrower_count);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_empty_bucket() {
        let oracle_price: u64 = 1_052;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::get_bucket_tcr(bucket, &oracle, &clock) == constants::max_u64(), 0);
            assert!(!bucket::has_liquidatable_bottle(bucket, &oracle, &clock), 0);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bottle::EBottleTooSmall)]
    fun test_borrow_too_small() {
        let oracle_price: u64 = 2_000;
        let coll_amount = vector[9_000_000_000];
        let debt_amount = vector[9_000_000_000];
        let (scenario_val, _) = setup_customly(oracle_price, coll_amount, debt_amount);
        test_scenario::end(scenario_val);
    }
}