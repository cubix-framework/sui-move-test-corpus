#[test_only]

module bucket_protocol::test_scale_factor {
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::clock::{Clock};
    use sui::transfer;
    use sui::balance;
    use std::vector;
    // use sui::test_utils;
    use bucket_protocol::constants::{decimal_factor};
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
    // use bucket_protocol::bkt::{BktTreasury};
    use bucket_oracle::bucket_oracle::{BucketOracle};
    // use bucket_protocol::bucket;
    use bucket_protocol::tank::{Self, ContributorToken};
    use bucket_protocol::test_utils::{
        dev,
        setup_customly, 
        get_coin_amount_times_decimal, 
        deposit_buck_to_tank,
        open_bottle_by_icr, 
        set_coll_price, 
        liquidate_normal_mode, 
        // check_bottle_info,
        withdraw_buck_from_tank,
        approx_equal
    };

    #[test]
    fun test_liquidate_succeeds_after_p_reduced_to_1() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[2000000000, 2500000000, 2500, 2500], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[10000000, 2000000000, 2000, 2000], 
            decimal_factor()
        );

        let (scenario_val, borrowers) =
            setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;

        // deposit buck to tank
        let depositors = vector<address>[@0x123, @0x456];
        let deposit_amount = get_coin_amount_times_decimal(
            vector<u64>[2010000000, 1], 
            decimal_factor()
        );
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            
            // record the tank value
            let p_before = tank::get_current_p(tank);
            assert!(p_before == 1000000000000000000, 0);
            // std::debug::print(&p_before);

            test_scenario::return_shared(protocol);
        };

        // coll price drop
        set_coll_price(scenario, 800);

        // liquidate borrower 1
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));

        // check p value
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            
            // record the tank value
            // let p_value = tank::get_current_p(tank);
            // std::debug::print(&p_value);
            // std::debug::print(&tank::get_current_epoch<BUCK, SUI>(tank));
            // std::debug::print(&tank::get_current_scale<BUCK, SUI>(tank));
            assert!(tank::get_current_scale<BUCK, SUI>(tank) == 1, 0);

            test_scenario::return_shared(protocol);
        };

        // check icr
        // check bottle icr is less than 100
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = buck::borrow_bucket<SUI>(&protocol);
            
            // let debtor = *vector::borrow(&borrowers, 2);
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

        // refill the tank deposit
        let depositors = vector<address>[@0x789];
        let deposit_amount = get_coin_amount_times_decimal(
            vector<u64>[2010000000], 
            decimal_factor()
        );
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        // check the liquidation works after scale = 1
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));

        // coll price rises
        set_coll_price(scenario, 1000);

        // get buck anmount
        // check the compounded stake and coll reward

        // let expected_buck_amount = vector<u64>[6650000000000, 13300000000000, 19950000000000];
        // let expected_coll_amount = vector<u64>[6633333333333, 13266666666666, 19900000000000];
        test_scenario::next_tx(scenario, @0x123);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank<SUI>(&protocol);
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

            // let buck_amount = tank::get_token_weight(tank, &token);
            // let reward_amount = tank::get_collateral_reward_amount(tank, &token);

            let (_token_deposit_amount,
                    _token_start_p,
                    _token_start_s,
                    _token_start_g,
                    _token_start_epoch,
                    token_start_scale 
            ) = tank::get_contributor_token_value(&token); 

            let scale_diff = tank::get_current_scale(tank) - token_start_scale;
            assert!(scale_diff == 1, 0);

            // test_utils::print(b"---------- buck_amount ----------");
            // std::debug::print(&buck_amount);
            // test_utils::print(b"---------- reward_amount ----------");
            // std::debug::print(&reward_amount);
            // test_utils::print(b"token value");
            // std::debug::print(&token_start_scale);
            // assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
            // assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_correct_reward_liquidation_succeeds_after_p_reduced_to_1() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[2000000000, 2500000000, 2500], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[10000000, 2000000000, 2000], 
            decimal_factor()
        );

        let (scenario_val, borrowers) =
            setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;

        // deposit buck to tank
        let depositors = vector<address>[@0xddd, @0xeee];
        let deposit_amount = get_coin_amount_times_decimal(
            vector<u64>[2010000000, 1], 
            decimal_factor()
        );
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            
            // record the tank value
            let p_before = tank::get_current_p(tank);
            assert!(p_before == 1000000000000000000, 0);

            test_scenario::return_shared(protocol);
        };

        // coll price drop
        set_coll_price(scenario, 800);

        // liquidate borrower 1
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));

        // check p value
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            
            assert!(tank::get_current_scale<BUCK, SUI>(tank) == 1, 0);

            test_scenario::return_shared(protocol);
        };

        // coll price drop
        set_coll_price(scenario, 1000);

        // withdraw all buck from tank
        let withdrawers = vector<address>[@0xddd, @0xeee];
        withdraw_buck_from_tank(scenario, withdrawers);

        // check icr
        // check bottle icr is less than 100
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = buck::borrow_bucket<SUI>(&protocol);
            
            // let debtor = *vector::borrow(&borrowers, 2);
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

        // A, B, C Deposit -> 2 liquidations -> D deposits -> 1 liquidation, all deposits and liquidations are 10000 BUCK
        // check stake and reward amount are correct
        let debt = get_coin_amount_times_decimal(
            vector<u64>[10000, 10000, 10000], 
            decimal_factor()
        );
        let icr = vector<u64>[200, 200, 200];
        let borrowers = vector<address>[@0x111, @0x222, @0x333];
        open_bottle_by_icr(debt, icr, borrowers, scenario);

        // A, B, C deposit 10000 BUCK to tank
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[10000, 10000, 10000], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);
        
        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 0));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));

        // D deposits to tank 10000 BUCK
        vector::push_back(&mut depositors, @0x011);
        test_scenario::next_tx(scenario, *vector::borrow(&depositors, 3));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(10000 * decimal_factor());
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            
            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        // liquidate 3
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));
        
        // check the compounded stake and coll reward
        let idx = 0;
        let expected_buck_amount = vector<u64>[1633417085427, 1633417085427, 1633417085427, 4949748743718];
        let expected_coll_amount = vector<u64>[16233668341709, 16233668341709, 16233668341709, 9798994974874];
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);
                
                // std::debug::print(&reward_amount);
                assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
                assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        // let expected_buck_amount = vector<u64>[6650000000000, 13300000000000, 19950000000000];
        // let expected_coll_amount = vector<u64>[6633333333333, 13266666666666, 19900000000000];
        // test_scenario::next_tx(scenario, @0x123);
        // {
        //     let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
        //     let tank = buck::borrow_tank<SUI>(&protocol);
        //     let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

        //     let buck_amount = tank::get_token_weight(tank, &token);
        //     let reward_amount = tank::get_collateral_reward_amount(tank, &token);

        //     let (_token_deposit_amount,
        //             _token_start_p,
        //             _token_start_s,
        //             _token_start_g,
        //             _token_start_epoch,
        //             token_start_scale 
        //     ) = tank::get_contributor_token_value(&token); 

        //     let scale_diff = tank::get_current_scale(tank) - token_start_scale;
        //     assert!(scale_diff == 1, 0);

        //     test_utils::print(b"---------- buck_amount ----------");
        //     std::debug::print(&buck_amount);
        //     test_utils::print(b"---------- reward_amount ----------");
        //     std::debug::print(&reward_amount);
        //     test_utils::print(b"token value");
        //     std::debug::print(&token_start_scale);
        //     // assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
        //     // assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

        //     transfer::public_transfer(token, test_scenario::sender(scenario));
        //     test_scenario::return_shared<BucketProtocol>(protocol);
        // };

        test_scenario::end(scenario_val);
    }
}