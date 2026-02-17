#[test_only]
module bucket_protocol::test_not_supported {
    use sui::balance;
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::test_scenario;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::buck::{Self, BucketProtocol, AdminCap};
    use bucket_protocol::bkt::BKT;
    use bucket_protocol::test_utils::{setup_empty, dev};

    #[test]
    #[expected_failure(abort_code = buck::ENotSupportedType)]
    fun test_no_bucket() {
        let oracle_price = 666_666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let _ = buck::borrow_bucket<BKT>(&protocol);
            test_scenario::return_shared(protocol);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::ENotSupportedType)]
    fun test_no_bucket_mut() {
        let oracle_price = 666_666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_input = balance::create_for_testing<BKT>(1);
            let buck_output = buck::borrow<BKT>(&mut protocol, &oracle, &clock, bkt_input, 1, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::ENotSupportedType)]
    fun test_no_well() {
        let oracle_price = 666_666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let _ = buck::borrow_well<BKT>(&protocol);
            test_scenario::return_shared(protocol);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::ENotSupportedType)]
    fun test_no_well_mut() {
        let oracle_price = 666_666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let _ = buck::borrow_well_mut<BKT>(&mut protocol);
            test_scenario::return_shared(protocol);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::ENotSupportedType)]
    fun test_no_tank() {
        let oracle_price = 666_666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let _ = buck::borrow_tank<BKT>(&protocol);
            test_scenario::return_shared(protocol);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::ENotSupportedType)]
    fun test_no_tank_mut() {
        let oracle_price = 666_666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let _ = buck::borrow_tank_mut<BKT>(&mut protocol);
            test_scenario::return_shared(protocol);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::EBucketAlreadyExists)]
    fun test_bucket_already_exists() {
        let oracle_price = 666_666;
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
}