#[test_only]

module bucket_protocol::test_recovery_mode {
    use sui::test_scenario;
    use std::vector;
    use sui::sui::SUI;
    use sui::clock::{Clock};
    // use sui::test_utils;
    use bucket_oracle::bucket_oracle::{BucketOracle};
    use bucket_protocol::constants::{decimal_factor};
    use bucket_protocol::bucket;
    use bucket_protocol::buck::{Self, BucketProtocol, borrow_bucket};
    use bucket_protocol::tank;
    use bucket_protocol::test_utils::{
        setup_customly, 
        get_coin_amount_times_decimal, 
        // open_bottle_by_icr, 
        set_coll_price, 
        liquidate_recovery_mode, 
        check_surplus_bottle_info,
        check_bottle_info,
        deposit_buck_to_tank,
        dev
    };

    #[test]
    fun test_is_in_recovery_mode() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[800, 800], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[500, 500], 
            decimal_factor()
        );

        let (scenario_val, _borrowers) = setup_customly(
            oracle_price, 
            coll, 
            debt
        );
        let scenario = &mut scenario_val;

        // check bucket tcr and is not in recovery mode
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = borrow_bucket<SUI>(&protocol);

            // std::debug::print(&bucket::get_bucket_tcr(bucket, &oracle, &clock));
            assert!(bucket::get_bucket_tcr(bucket, &oracle, &clock) == 15920, 0);

            // check is not in recovery mode
            assert!(!bucket::is_in_recovery_mode(bucket, &oracle, &clock), 1);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // check in recovery mode
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = borrow_bucket<SUI>(&protocol);

            // check is in recovery mode
            assert!(bucket::is_in_recovery_mode(bucket, &oracle, &clock), 2);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    // icr less than 100%, only redistribution, no absorb
    fun test_icr_less_than_100() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[800, 800, 800], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[500, 500, 500], 
            decimal_factor()
        );

        let (scenario_val, borrowers) = setup_customly(
            oracle_price, 
            coll, 
            debt
        );
        let scenario = &mut scenario_val;

        // deposit buck to tank
        let depositors = vector<address>[@0x123];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[6000], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        let p_before;
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            
            // record the tank value
            p_before = tank::get_current_p(tank);
            assert!(p_before == 1000000000000000000, 0);

            test_scenario::return_shared(protocol);
        };
        
        // coll price drop
        set_coll_price(scenario, 500);

        // check bottle icr is less than 100
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = borrow_bucket<SUI>(&protocol);
            
            let debtor = *vector::borrow(&borrowers, 0);
            // check icr = 119
            let icr = bucket::get_bottle_icr<SUI>(bucket, &oracle, &clock, debtor);
            assert!(icr < 100_00, 0);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // liquidate borrower 0
        liquidate_recovery_mode(scenario, *vector::borrow(&borrowers, 0));
        
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            
            // record the tank value
            let p_after = tank::get_current_p(tank);
            assert!(p_before != p_after, 0);

            test_scenario::return_shared(protocol);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::ETankEmptyInRecoveryMode)]
    // icr > 110%, icr < tcr, tank is empty, do nothing
    fun test_icr_large_than_110() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[1050, 750], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[500, 500], 
            decimal_factor()
        );

        let (scenario_val, borrowers) = setup_customly(
            oracle_price, 
            coll, 
            debt
        );
        let scenario = &mut scenario_val;
        
        // coll price drop
        set_coll_price(scenario, 800);

        // check bottle icr is less than 100
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = borrow_bucket<SUI>(&protocol);
            
            // let debtor = *vector::borrow(&borrowers, 1);
            // check icr = 119
            // let icr = bucket::get_bottle_icr<SUI>(bucket, &oracle, &clock, debtor);
            // let tcr = bucket::get_bucket_tcr<SUI>(bucket, &oracle, &clock);
            // std::debug::print(&icr);
            // std::debug::print(&tcr);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // liquidate borrower 1
        // it should abort
        liquidate_recovery_mode(scenario, *vector::borrow(&borrowers, 1));
        
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = tank::ETankEmpty)]
    // 100 < icr < 110
    fun test_icr_between_100_and_110() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[1050, 750], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[500, 500], 
            decimal_factor()
        );

        let (scenario_val, borrowers) = setup_customly(
            oracle_price, 
            coll, 
            debt
        );
        let scenario = &mut scenario_val;
        
        // coll price drop
        set_coll_price(scenario, 520);

        // check bottle icr
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = borrow_bucket<SUI>(&protocol);
            
            // let debtor = *vector::borrow(&borrowers, 0);
            // check icr = 119
            // let icr = bucket::get_bottle_icr<SUI>(bucket, &oracle, &clock, debtor);
            // std::debug::print(&icr);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // liquidate borrower 0
        liquidate_recovery_mode(scenario, *vector::borrow(&borrowers, 0));
        
        test_scenario::end(scenario_val);
    }

    #[test]
    // tcr > icr > 110%, tank absorb all
    fun test_icr_between_mcr_and_tcr_tank_absorb_all() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[1000, 750, 800], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[500, 500, 500], 
            decimal_factor()
        );

        let (scenario_val, borrowers) = setup_customly(
            oracle_price, 
            coll, 
            debt
        );
        let scenario = &mut scenario_val;

        // deposit buck to tank
        let depositors = vector<address>[@0x123];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[1000], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);
        
        // coll price drop
        set_coll_price(scenario, 800);

        // check bottle icr is less than 100
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = borrow_bucket<SUI>(&protocol);
            
            // let debtor = *vector::borrow(&borrowers, 1);
            // check icr
            // let icr = bucket::get_bottle_icr<SUI>(bucket, &oracle, &clock, debtor);
            // let tcr = bucket::get_bucket_tcr<SUI>(bucket, &oracle, &clock);
            // test_utils::print(b"---------- icr ----------");
            // std::debug::print(&icr);
            // test_utils::print(b"---------- tcr ----------");
            // std::debug::print(&tcr);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // liquidate borrower 1
        liquidate_recovery_mode(scenario, *vector::borrow(&borrowers, 1));

        // check surplus bottle balance
        check_surplus_bottle_info(
            scenario, 
            *vector::borrow(&borrowers, 1), 
            59062500000, 
            0
        );
        
        test_scenario::end(scenario_val);
    }

    #[test]
    // tcr > icr > 110%, tank absorb portion
    fun test_icr_between_mcr_and_tcr_tank_absorb_portion() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[1000, 750, 800], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[500, 500, 500], 
            decimal_factor()
        );

        let (scenario_val, borrowers) = setup_customly(
            oracle_price, 
            coll, 
            debt
        );
        let scenario = &mut scenario_val;

        // deposit buck to tank
        let depositors = vector<address>[@0x123];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[300], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);
        
        // coll price drop
        set_coll_price(scenario, 800);

        // check bottle icr is less than 100
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = borrow_bucket<SUI>(&protocol);
            
            // let debtor = *vector::borrow(&borrowers, 1);
            // check icr
            // let icr = bucket::get_bottle_icr<SUI>(bucket, &oracle, &clock, debtor);
            // let tcr = bucket::get_bucket_tcr<SUI>(bucket, &oracle, &clock);
            // test_utils::print(b"---------- icr ----------");
            // std::debug::print(&icr);
            // test_utils::print(b"---------- tcr ----------");
            // std::debug::print(&tcr);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // liquidate borrower 1
        liquidate_recovery_mode(scenario, *vector::borrow(&borrowers, 1));

        // check surplus bottle balance
        check_bottle_info(
            scenario, 
            *vector::borrow(&borrowers, 1), 
            337500000000, 
            202499999999
        );
        
        test_scenario::end(scenario_val);
    }

}