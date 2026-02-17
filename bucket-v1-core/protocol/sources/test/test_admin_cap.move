#[test_only]
module bucket_protocol::test_admnin_cap {
    use sui::sui::SUI;
    use sui::balance;
    use sui::clock::Clock;
    use sui::test_scenario;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::buck::{Self, BucketProtocol, AdminCap};
    use bucket_protocol::test_utils::{setup_empty, dev};

    #[test]
    #[expected_failure(abort_code = buck::EBucketAlreadyExists)]
    fun test_bucket_already_exists() {
        let oracle_price = 6666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            buck::create_bucket<SUI>(&admin_cap, &mut protocol, 110, 150, 9, std::option::none(), test_scenario::ctx(scenario));
            test_scenario::return_shared(protocol);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_min_bottle_size() {
        let oracle_price = 2000;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            buck::update_min_bottle_size(&admin_cap, &mut protocol, 5_000_000_000);
            test_scenario::return_shared(protocol);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        let borrower = @0x999;
        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let sui_input_amount: u64 = 6_000_000_000;
            let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
            let buck_output_amount: u64 = 6_000_000_000;
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, std::option::none(), test_scenario::ctx(scenario));
            assert!(balance::value(&buck_output) == buck_output_amount, 0);
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }
}