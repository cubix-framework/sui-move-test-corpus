#[test_only]

module bucket_protocol::test_tank {
    use sui::balance;
    use sui::sui::SUI;
    use sui::test_scenario;
    use sui::clock::{Clock};
    use sui::transfer;
    // use sui::test_utils;
    use std::vector;
    use bucket_protocol::bucket::{Self, bottle_exists};
    use bucket_protocol::bkt::BktTreasury;
    use bucket_protocol::tank::{Self, ContributorToken};
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol, borrow_bucket};
    use bucket_oracle::bucket_oracle::{BucketOracle};
    use bucket_protocol::constants::decimal_factor;
    use bucket_protocol::test_utils::{
        setup_customly, 
        setup_empty, 
        dev, 
        get_coin_amount_times_decimal, 
        approx_equal, 
        set_coll_price, 
        deposit_buck_to_tank,
        liquidate_normal_mode,
        liquidate_recovery_mode
    };

    #[test]
    // deposit 500 BUCK, check tank has 500 BUCK
    fun test_deposit_buck() {
        let oracle_price: u64 = 1000;
        let (scenario_val) = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let min_bottle_size = buck::get_min_bottle_size(&protocol);
            let buck_input = balance::create_for_testing<BUCK>(min_bottle_size);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol); 
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, test_scenario::sender(scenario));
            assert!(tank::get_reserve_balance(tank) == min_bottle_size, 0);

            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_check_correctly_update_token() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[30000, 1000, 1000, 3000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[10000, 500, 500, 600], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // borrower 1 deposit 10000 BUCK to tank
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(*vector::borrow(&debt, 0));
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, test_scenario::sender(scenario));
            assert!(tank::get_reserve_balance(tank) == *vector::borrow(&debt, 0), 0);

            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 2 3 and comfirm the bottle is closed
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let tank_buck_balance_before = tank::get_reserve_balance(tank);

            // liquidate bottle
            let debtor1 = *vector::borrow(&borrowers, 1);
            let liquidation_fee = buck::liquidate_under_normal_mode<SUI>(&mut protocol, &oracle, &clock, debtor1);
            balance::destroy_for_testing<SUI>(liquidation_fee);

            let debtor2 = *vector::borrow(&borrowers, 2);
            let liquidation_fee = buck::liquidate_under_normal_mode<SUI>(&mut protocol, &oracle, &clock, debtor2);
            balance::destroy_for_testing<SUI>(liquidation_fee);

            // check tank buck balance < before
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let tank_buck_balance_after = tank::get_reserve_balance(tank);
            assert!(tank_buck_balance_after < tank_buck_balance_before, 0);

            // check the bottle is closed
            let bucket = borrow_bucket<SUI>(&protocol);
            assert!(!bottle_exists(bucket, debtor1), 1);
            assert!(!bottle_exists(bucket, debtor2), 1);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 3));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            
            // record the tank value
            let p_before = tank::get_current_p(tank);
            let s_before = tank::get_epoch_scale_sum_map(tank, 0, 0);
            let g_before = tank::get_epoch_scale_gain_map(tank, 0, 0);
            assert!(p_before > 0, 0);
            assert!(s_before > 0, 0);
            assert!(g_before == 0, 0);
            
            // make deposit
            let buck_input = balance::create_for_testing<BUCK>(100 * decimal_factor());
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            
            // check the tank value is updated
            let ( _, p_after, s_after, g_after, _, _) = tank::get_contributor_token_value(&token);
            assert!(p_after == p_before, 0);
            assert!(s_after == s_before, 0);
            assert!(g_after == g_before, 0);

            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    fun test_abort_when_bucket_has_liquidatable_bottle() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[30000, 1000, 1000, 3000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[10000, 500, 500, 600], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // borrower 1 deposit 10000 BUCK to tank
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(*vector::borrow(&debt, 0));
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, test_scenario::sender(scenario));
            assert!(tank::get_reserve_balance(tank) == *vector::borrow(&debt, 0), 0);

            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // borrower 1 withdraw 10000 BUCK from tank, should abort
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            let (buck_output, sui_output, bkt_reward) = 
                buck::tank_withdraw<SUI>(
                    &mut protocol,
                    &oracle,
                    &clock,
                    &mut bkt_treasury,
                    token,
                    test_scenario::ctx(scenario),
                );

            balance::destroy_for_testing(bkt_reward);
            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(sui_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_treasury);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_withdraw_correct_amount_and_reward() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[10000000, 1000, 150000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[1000000, 500, 15000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // borrower 1 deposit 185000 BUCK to tank
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(185000 * decimal_factor());
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            
            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        // borrower 3 deposit 15000 BUCK to tank
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 2));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(15000 * decimal_factor());
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            
            assert!(tank::get_reserve_balance(tank) == 200000 * decimal_factor(), 0);
            
            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        // coll price drop
        set_coll_price(scenario, 500);

        let debtor_debt_amount;
        // liquidate borrower 2 and comfirm the bottle is closed
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (_, debt_amount) = bucket::get_bottle_info_by_debtor(bucket, *vector::borrow(&borrowers, 1));
            debtor_debt_amount = debt_amount;
            
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let tank_buck_balance_before = tank::get_reserve_balance(tank);

            
            // liquidate bottle
            let debtor1 = *vector::borrow(&borrowers, 1);
            let liquidation_fee = buck::liquidate_under_normal_mode<SUI>(&mut protocol, &oracle, &clock, debtor1);
            balance::destroy_for_testing<SUI>(liquidation_fee);

            // check tank buck balance < before
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let tank_buck_balance_after = tank::get_reserve_balance(tank);
            assert!(tank_buck_balance_after < tank_buck_balance_before, 0);

            // check the bottle is closed
            let bucket = borrow_bucket<SUI>(&protocol);
            assert!(!bottle_exists(bucket, debtor1), 1);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // 2 withdraw, check balance
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 2));
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_teasury = test_scenario::take_shared<BktTreasury>(scenario);

            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            let (buck_output, sui_output, bkt_reward) = 
                buck::tank_withdraw<SUI>(
                    &mut protocol,
                    &oracle,
                    &clock,
                    &mut bkt_teasury,
                    token,
                    test_scenario::ctx(scenario),
                );

            let buck_output_amount = balance::value(&buck_output);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);

            assert!(buck_output_amount == (15000 * decimal_factor() - 15000 * debtor_debt_amount / 200000) , 0);
            assert!(tank::get_reserve_balance(tank) == (200000 * decimal_factor() - buck_output_amount - debtor_debt_amount), 0);

            let sui_output_amount = balance::value(&sui_output);
            assert!(sui_output_amount == 975 * 15000 * decimal_factor() / 200000, 0);
            
            balance::destroy_for_testing(bkt_reward);
            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(sui_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_teasury);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_withdraw_0_reward_with_no_intermediate_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[10000000, 1000, 150000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[1000000, 500, 15000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // borrower 1 deposit 185000 BUCK to tank
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(185000 * decimal_factor());
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            
            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        // borrower 3 deposit 15000 BUCK to tank
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 2));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(15000 * decimal_factor());
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            
            assert!(tank::get_reserve_balance(tank) == 200000 * decimal_factor(), 0);
            
            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };


        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 2 and comfirm the bottle is closed
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let tank_buck_balance_before = tank::get_reserve_balance(tank);
            
            // liquidate bottle
            let debtor1 = *vector::borrow(&borrowers, 1);
            let liquidation_fee = buck::liquidate_under_normal_mode<SUI>(&mut protocol, &oracle, &clock, debtor1);
            balance::destroy_for_testing<SUI>(liquidation_fee);

            // check tank buck balance < before
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let tank_buck_balance_after = tank::get_reserve_balance(tank);
            assert!(tank_buck_balance_after < tank_buck_balance_before, 0);

            // check the bottle is closed
            let bucket = borrow_bucket<SUI>(&protocol);
            assert!(!bottle_exists(bucket, debtor1), 1);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // 2 withdraw and deposit and withdraw again
        let borrower = *vector::borrow(&borrowers, 2);
        test_scenario::next_tx(scenario, borrower);
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);

            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            let (buck_output, sui_output, bkt_reward) = 
                buck::tank_withdraw<SUI>(
                    &mut protocol,
                    &oracle,
                    &clock,
                    &mut bkt_treasury,
                    token,
                    test_scenario::ctx(scenario),
                );

            balance::destroy_for_testing(bkt_reward);
            balance::destroy_for_testing(sui_output);
            
            // second deposit 
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_output, test_scenario::ctx(scenario));
            transfer::public_transfer(token, borrower);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_treasury);
        };

        test_scenario::next_tx(scenario, borrower);
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            
            // withdraw again
            let (buck_output, sui_output, bkt_reward) = 
                buck::tank_withdraw<SUI>(
                    &mut protocol,
                    &oracle,
                    &clock,
                    &mut bkt_treasury,
                    token,
                    test_scenario::ctx(scenario),
                );
            assert!(balance::value(&sui_output) == 0, 0);
            assert!(balance::value(&bkt_reward) == 0, 0);

            balance::destroy_for_testing(bkt_reward);
            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(sui_output);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_treasury);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_withdraw_success_after_price_change_in_recovery_mode() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[5000, 1000, 20000, 20000, 20000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[500, 500, 10000, 10000, 10000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        let idx = 2u64;
        while (idx < vector::length(&borrowers)) {    
            // borrower deposit 10000 BUCK to tank
            test_scenario::next_tx(scenario, *vector::borrow(&borrowers, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let buck_input = balance::create_for_testing<BUCK>(10000 * decimal_factor());
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
                
                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        // coll price drop
        set_coll_price(scenario, 600);

        // liquidate borrower 2 and comfirm the bottle is closed
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = borrow_bucket<SUI>(&protocol);
            
            // liquidate bottle, debtor1's bottle can be absorb by tank
            let debtor1 = *vector::borrow(&borrowers, 1);

            // check icr = 119
            // let icr = bucket::get_bottle_icr<SUI>(bucket, &oracle, &clock, debtor1);
            // std::debug::print(&icr);
            let liquidation_fee = buck::liquidate_under_recovery_mode<SUI>(&mut protocol, &oracle, &clock, debtor1);
            balance::destroy_for_testing<SUI>(liquidation_fee);

            // check the bottle's debt is 0, the bottle should in another table
            let bucket = borrow_bucket<SUI>(&protocol);
            let (_bottle_coll_amount, bottle_debt_amount) = bucket::get_surplus_bottle_info_by_debtor(bucket, debtor1);
            assert!(bottle_debt_amount == 0, 0);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        // coll price rise
        set_coll_price(scenario, 1000);

        // withdraw successfully
        idx = 2u64;
        while (idx < vector::length(&borrowers)) {
            test_scenario::next_tx(scenario, *vector::borrow(&borrowers, idx));
            {
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);
                let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
                let (buck_output, sui_output, bkt_reward) = 
                    buck::tank_withdraw<SUI>(
                        &mut protocol,
                        &oracle,
                        &clock,
                        &mut bkt_treasury,
                        token,
                        test_scenario::ctx(scenario),
                    );
                
                balance::destroy_for_testing(bkt_reward);
                balance::destroy_for_testing(buck_output);
                balance::destroy_for_testing(sui_output);

                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
                test_scenario::return_shared(bkt_treasury);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_under_recovery_mode_icr_less_than_100() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[5000, 1000, 20000, 20000, 20000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[500, 500, 10000, 10000, 10000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        let idx = 2u64;
        while (idx < vector::length(&borrowers)) {    
            // borrower deposit 10000 BUCK to tank
            test_scenario::next_tx(scenario, *vector::borrow(&borrowers, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let buck_input = balance::create_for_testing<BUCK>(10000 * decimal_factor());
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
                
                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 2 and comfirm the bottle is closed
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // let bucket = borrow_bucket<SUI>(&protocol);
            
            let debtor1 = *vector::borrow(&borrowers, 1);

            // check icr = 99
            // let icr = bucket::get_bottle_icr<SUI>(bucket, &oracle, &clock, debtor1);
            // std::debug::print(&icr);
            let liquidation_fee = buck::liquidate_under_recovery_mode<SUI>(&mut protocol, &oracle, &clock, debtor1);
            balance::destroy_for_testing<SUI>(liquidation_fee);

            // check the bottle is closed
            let bucket = borrow_bucket<SUI>(&protocol);
            assert!(!bottle_exists(bucket, debtor1), 1);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    // Depositors with equal initial deposit
    // Check correct compounded stake and coll reward after one liquidation
    fun test_compound_stake_and_reward_amount_with_equal_deposit_one_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000 BUCK to tank
        let idx: u64 = 0;
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        while (idx < vector::length(&depositors)) {    
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let buck_input = balance::create_for_testing<BUCK>(10000 * decimal_factor());
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
                
                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));

        // check the compounded stake and coll reward
        idx = 0;
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);

                assert!(buck_amount == 6650000000000, 1);
                assert!(reward_amount == 6500000000000, 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_compound_stake_and_reward_amount_with_equal_deposit_two_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 20000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 10000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000 BUCK to tank
        let idx: u64 = 0;
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        while (idx < vector::length(&depositors)) {    
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let buck_input = balance::create_for_testing<BUCK>(10000 * decimal_factor());
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
                
                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));

        // check the compounded stake and coll reward
        idx = 0;
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);

                // std::debug::print(&buck_amount);
                // std::debug::print(&reward_amount);
                assert!(approx_equal(buck_amount, 3300000000000, 10), 1);
                assert!(approx_equal(reward_amount, 13000000000000, 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_compound_stake_and_reward_amount_with_equal_deposit_three_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 20000, 20000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 10000, 10000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000 BUCK to tank
        let idx: u64 = 0;
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        while (idx < vector::length(&depositors)) {    
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let buck_input = balance::create_for_testing<BUCK>(10000 * decimal_factor());
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
                
                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));
        // liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 3));

        // // check the compounded stake and coll reward
        // idx = 0;
        // while (idx < vector::length(&depositors)) {
        //     test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
        //     {
        //         let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
        //         let tank = buck::borrow_tank<SUI>(&protocol);
        //         let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

        //         let buck_amount = tank::get_token_weight(tank, &token);
        //         let reward_amount = tank::get_collateral_reward_amount(tank, &token);

        //         assert!(approx_equal(buck_amount, 0, 1), 1);
        //         assert!(approx_equal(reward_amount, 19800995024875, 10), 1);

        //         transfer::public_transfer(token, test_scenario::sender(scenario));
        //         test_scenario::return_shared<BucketProtocol>(protocol);
        //     };
        //     idx = idx + 1;
        // };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_compound_stake_and_reward_amount_with_equal_deposit_two_inc_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 10000, 14000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 5000, 7000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000 BUCK to tank
        let idx: u64 = 0;
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        while (idx < vector::length(&depositors)) {    
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let buck_input = balance::create_for_testing<BUCK>(10000 * decimal_factor());
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
                
                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));

        // check the compounded stake and coll reward
        idx = 0;
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);

                // (30000 - 5000 * 1.005 - 7000 * 1.005) / 3
                assert!(approx_equal(buck_amount, 5980000000000, 10), 1);
                // (10000 + 14000) * 0.995 / 3
                assert!(approx_equal(reward_amount, 7800000000000, 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_compound_stake_and_reward_amount_with_vary_deposit_two_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 20000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 10000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000 BUCK to tank
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[10000, 20000, 30000], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));

        // check the compounded stake and coll reward
        let idx = 0;
        let expected_buck_amount = vector<u64>[6650000000000, 13300000000000, 19950000000000];
        let expected_coll_amount = vector<u64>[6500000000000, 13000000000000, 19500000000000];
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);

                assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
                assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_compound_stake_and_reward_amount_with_vary_deposit_three_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 20000, 20000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 10000, 10000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000, 20000, 30000 BUCK to tank
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[10000, 20000, 30000], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 3));

        // check the compounded stake and coll reward
        let idx = 0;
        let expected_buck_amount = vector<u64>[4975000000000, 9950000000000, 14925000000000];
        let expected_coll_amount = vector<u64>[9750000000000, 19500000000000, 29250000000000];
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);
                
                assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
                assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_compound_stake_and_reward_amount_with_vary_deposit_three_vary_liquidation() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 414000, 10000, 93400], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 207000, 5000, 46700], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000, 20000, 30000 BUCK to tank
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[2000, 456000, 13100], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2 3
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 3));

        // check the compounded stake and coll reward
        let idx = 0;
        let expected_buck_amount = vector<u64>[896227977074, 204339978773084, 5870293249840];
        let expected_coll_amount = vector<u64>[2141647208660, 488295563574612, 14027789216726];
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);
                
                assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
                assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    // A, B, C Deposit -> 2 liquidations -> D deposits -> 1 liquidation, all deposits and liquidations are 10000 BUCK
    fun test_compound_stake_and_reward_amount_1() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 20000, 20000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 10000, 10000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 10000 BUCK to tank
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[10000, 10000, 10000], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));

        // D deposits to tank 10000 BUCK
        vector::push_back(&mut depositors, @0xabc);
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
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 3));
        
        // check the compounded stake and coll reward
        let idx = 0;
        let expected_buck_amount = vector<u64>[1633417085427, 1633417085427, 1633417085427, 4949748743718];
        let expected_coll_amount = vector<u64>[16233668341707, 16233668341707, 16233668341707, 9798994974874];
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);
                
                assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
                assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    // A, B, C Deposit -> 2 liquidations -> D deposits -> 2 liquidations
    fun test_compound_stake_and_reward_amount_2() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(
            vector<u64>[1000000, 20000, 50000, 10000, 80000], 
            decimal_factor()
        );
        let debt = get_coin_amount_times_decimal(
            vector<u64>[100000, 10000, 25000, 5000, 40000], 
            decimal_factor()
        );

        let (scenario_val, borrowers) = setup_customly(
            oracle_price,
            coll, 
            debt
        );
        let scenario = &mut scenario_val;
        
        // A, B, C deposit 60000, 20000, 15000 BUCK to tank
        let depositors = vector<address>[@0x123, @0x456, @0x789];
        let deposit_amount = get_coin_amount_times_decimal(vector<u64>[60000, 20000, 15000], decimal_factor());
        deposit_buck_to_tank(scenario, depositors, deposit_amount);

        // coll price drop
        set_coll_price(scenario, 500);

        // liquidate borrower 1 2
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 2));

        // D deposits to tank 25000 BUCK
        vector::push_back(&mut depositors, @0xddd);
        test_scenario::next_tx(scenario, @0xddd);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let buck_input = balance::create_for_testing<BUCK>(25000 * decimal_factor());
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            
            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        // liquidate 3 4
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 3));
        liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 4));
        
        // check the compounded stake and coll reward
        let idx = 0;
        let expected_buck_amount = vector<u64>[17639313136953, 5879771045651, 4409828284238, 11671087533156];
        let expected_coll_amount = vector<u64>[82192377495462, 27397459165153, 20548094373865, 25862068965517];
        while (idx < vector::length(&depositors)) {
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let tank = buck::borrow_tank<SUI>(&protocol);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

                let buck_amount = tank::get_token_weight(tank, &token);
                let reward_amount = tank::get_collateral_reward_amount(tank, &token);
                
                assert!(approx_equal(buck_amount, *vector::borrow(&expected_buck_amount, idx), 10), 1);
                assert!(approx_equal(reward_amount, *vector::borrow(&expected_coll_amount, idx), 10), 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_100_deposit_50_liquidation() {
        let oracle_price: u64 = 1000;
        let coll_input = vector<u64>[
            20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000,
            1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000
        ];
        let debt_input = vector<u64>[
            10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000,
            500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500
        ];
        let coll = get_coin_amount_times_decimal(coll_input, decimal_factor());
        let debt = get_coin_amount_times_decimal(debt_input, decimal_factor());

        let (scenario_val, borrowers) = setup_customly(oracle_price, coll, debt);
        let scenario = &mut scenario_val;

        // 100 deposit 100 BUCK to tank
        let deposit_input = vector<u64>[
            1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000
        ];
        let deposit_amount = get_coin_amount_times_decimal(deposit_input, decimal_factor());
        deposit_buck_to_tank(scenario, borrowers, deposit_amount);

        // coll price drop
        set_coll_price(scenario, 500);

        // 50 liquidate start from borrower 
        let idx = 100;
        while(idx < vector::length(&borrowers)) {
            liquidate_recovery_mode(scenario, *vector::borrow(&borrowers, idx));
            idx = idx + 1;
        };

        // check stake and reward
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank<SUI>(&protocol);
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);

            let buck_amount = tank::get_token_weight(tank, &token);
            let reward_amount = tank::get_collateral_reward_amount(tank, &token);

            assert!(reward_amount == 487500000000, 0);
            assert!(buck_amount == 748750000000, 0);
            
            transfer::public_transfer(token, test_scenario::sender(scenario));
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = tank::EDepositAndWithdrawInSameTxn)]
    fun test_deposit_and_withdraw_in_same_txn_but_tank_not_empty() {
        let oracle_price: u64 = 1000;
        let (scenario_val, borrowers) = setup_customly(
            oracle_price,
            vector[20_000_000_000, 1_000_000_000_000_000], 
            vector[10_000_000_000, 10_000_000_000],
        );
        let borrower = *vector::borrow(&borrowers, 0);
        let scenario = &mut scenario_val;
        
        // someone deposit in tank
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let min_bottle_size = buck::get_min_bottle_size(&protocol);
            let buck_input = balance::create_for_testing<BUCK>(min_bottle_size);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol); 
            let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, test_scenario::sender(scenario));
            assert!(tank::get_reserve_balance(tank) == min_bottle_size, 0);

            test_scenario::return_shared<BucketProtocol>(protocol);
        };

        set_coll_price(scenario, 500);

        // flash liquidation (not allow when tank is not empty)
        let liquidator = @0xcafe;
        test_scenario::next_tx(scenario, liquidator);
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            
            let buck_amount = 1_000_000_000_000;
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_in = balance::create_for_testing<BUCK>(buck_amount);
            let token = tank::deposit<BUCK, SUI>(tank, buck_in, test_scenario::ctx(scenario));

            let rebate = buck::liquidate_under_normal_mode<SUI>(
                &mut protocol, &oracle, &clock, borrower,
            );
            assert!(balance::value(&rebate) == 100_000_000, 0);
            balance::destroy_for_testing(rebate);

            let (buck_output, sui_output, bkt_reward) = 
                buck::tank_withdraw<SUI>(
                    &mut protocol,
                    &oracle,
                    &clock,
                    &mut bkt_treasury,
                    token,
                    test_scenario::ctx(scenario),
                );
            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(bkt_reward);
            balance::destroy_for_testing(sui_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_treasury);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_deposit_and_withdraw_in_same_txn_when_tank_is_empty() {
        let oracle_price: u64 = 1000;
        let (scenario_val, borrowers) = setup_customly(
            oracle_price,
            vector[20_000_000_000, 1_000_000_000_000_000], 
            vector[10_000_000_000, 10_000_000_000],
        );
        let borrower = *vector::borrow(&borrowers, 0);
        let scenario = &mut scenario_val;
        
        set_coll_price(scenario, 500);

        // flash liquidation (allow when tank is empty)
        let liquidator = @0xcafe;
        test_scenario::next_tx(scenario, liquidator);
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            
            let buck_amount = 1_000_000_000_000;
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_in = balance::create_for_testing<BUCK>(buck_amount);
            let token = tank::deposit<BUCK, SUI>(tank, buck_in, test_scenario::ctx(scenario));
            assert!(tank::get_reserve_balance(tank) == buck_amount, 0);

            let rebate = buck::liquidate_under_normal_mode<SUI>(
                &mut protocol, &oracle, &clock, borrower,
            );
            assert!(balance::value(&rebate) == 100_000_000, 0);
            balance::destroy_for_testing(rebate);

            let (buck_output, sui_output, bkt_reward) = 
                buck::tank_withdraw<SUI>(
                    &mut protocol,
                    &oracle,
                    &clock,
                    &mut bkt_treasury,
                    token,
                    test_scenario::ctx(scenario),
                );
            let tank = buck::borrow_tank<SUI>(&protocol);
            assert!(tank::get_reserve_balance(tank) == 0, 0);
            assert!(balance::value(&buck_output) == buck_amount - 10_050_000_000, 0);
            assert!(balance::value(&sui_output) == 19_500_000_000, 0);
            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(bkt_reward);
            balance::destroy_for_testing(sui_output);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(bkt_treasury);
        };

        test_scenario::end(scenario_val);
    }
}