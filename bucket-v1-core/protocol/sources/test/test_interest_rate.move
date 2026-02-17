#[test_only]
module bucket_protocol::test_interest_rate {
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use std::vector;
    use sui::test_scenario;
    use sui::balance;
    use sui::transfer;
    use bucket_protocol::buck::{Self, BucketProtocol, AdminCap, BUCK};
    use bucket_protocol::test_utils::{
        setup_empty, 
        setup_customly_with_interest, 
        setup_empty_with_interest, 
        dev, 
        get_coin_amount_times_decimal,
        liquidate_normal_mode,
        set_coll_price
    };
    use bucket_protocol::bucket;
    use bucket_protocol::interest;
    use bucket_protocol::constants::decimal_factor;
    use bucket_protocol::tank::{Self, ContributorToken};

    #[test]
    public fun test_add_interest_table_to_existing_bucket() {
        let oracle_price = 6666;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            buck::add_interest_table_to_bucket<SUI>(&admin_cap, &mut protocol, &clock, test_scenario::ctx(scenario));
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let interest_table = bucket::borrow_interest_table<SUI>(bucket);
            let (interest_rate, active_interest_index, last_active_index_update, interest_payable) = interest::get_interest_table_info(interest_table);
            assert!(interest_rate == 0, 0);
            assert!(active_interest_index == 1000000000000000000000000000, 0);
            assert!(last_active_index_update == 1687881600000, 0);
            assert!(interest_payable == 0, 0);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    public fun test_set_interest_rate() {
        let oracle_price: u64 = 1000;
        let scenario_val = setup_empty_with_interest(oracle_price);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);

            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let interest_table = bucket::borrow_interest_table<SUI>(bucket);
            let (interest_rate, _, _, _) = interest::get_interest_table_info(interest_table);
            assert!(interest_rate == 0, 0);

            buck::set_interest_rate<SUI>(&admin_cap, &mut protocol, 400, &clock);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let interest_table = bucket::borrow_interest_table<SUI>(bucket);
            let (new_interest_rate, _, _, _) = interest::get_interest_table_info(interest_table);
            assert!(new_interest_rate == 1268391679350583, 0);
            
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    public fun test_open_new_bottle_and_accrue_interest() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[30000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly_with_interest(oracle_price, coll, debt);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            buck::set_interest_rate<SUI>(&admin_cap, &mut protocol, 400, &clock);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            clock::increment_for_testing(&mut clock, 31536000000);
            let (_, debt_amount) = bucket::get_bottle_info_with_interest_by_debtor(bucket, *vector::borrow(&borrowers, 0), &clock);
            assert!(debt_amount == 10451999999999, 0);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    // Depositors with equal initial deposit
    // Check correct compounded stake and coll reward after one liquidation
    fun test_compound_stake_and_reward_amount_with_equal_deposit_one_liquidation_with_interest() {
        let oracle_price: u64 = 1000;
        let coll = get_coin_amount_times_decimal(vector<u64>[1000000, 20000], decimal_factor());
        let debt = get_coin_amount_times_decimal(vector<u64>[100000, 10000], decimal_factor());

        let (scenario_val, borrowers) = setup_customly_with_interest(oracle_price, coll, debt);
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

        // inc time 1 year
        test_scenario::next_tx(scenario, dev());
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            buck::set_interest_rate<SUI>(&admin_cap, &mut protocol, 400, &clock);
            clock::increment_for_testing(&mut clock, 31536000000);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(clock);
            test_scenario::return_shared<BucketProtocol>(protocol);
        };

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
                
                assert!(buck_amount == 6516000000000, 1);
                assert!(reward_amount == 6500000000000, 1);

                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };

        test_scenario::end(scenario_val);
    }
}