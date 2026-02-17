#[test_only]
module bucket_protocol::test_liquidate {
    use sui::balance;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, Scenario};
    use sui::test_utils;
    use sui::address;
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use std::vector;
    use std::option;
    use sui::coin;

    use bucket_framework::math::mul_factor;
    use bucket_protocol::well;
    use bucket_protocol::bucket;
    use bucket_protocol::tank::{Self, ContributorToken};
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol, AdminCap};
    use bucket_protocol::bkt::{Self, BKT, BktTreasury, BktAdminCap};
    use bucket_oracle::bucket_oracle::{Self, BucketOracle, AdminCap as OracleAdminCap};
    use bucket_protocol::constants;

    #[test_only]
    public fun setup(user: address): (Clock, Scenario, BucketProtocol, BucketOracle, OracleAdminCap, AdminCap) {
        let scenario_val = test_scenario::begin(user);
        let scenario = &mut scenario_val;
        let clock = clock::create_for_testing(test_scenario::ctx(scenario));
        let (protocol, admin_cap) = buck::new_for_testing( test_utils::create_one_time_witness<BUCK>(), test_scenario::ctx(scenario));
        let (oracle, ocap) = bucket_oracle::new_for_testing<SUI>(3, test_scenario::ctx(scenario));

        (clock, scenario_val, protocol, oracle, ocap, admin_cap)
    }
    
    #[test]
    fun test_liquidate(): (BucketProtocol, BucketOracle, OracleAdminCap, BktTreasury, BktAdminCap) {

        let dev = @0xde1;
        let borrowers = vector<address>[];
        let borrower_count = 3;
        let idx = 1u8;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256((idx as u256) + 10));
            idx = idx + 1;
        };

        let (clock, scenario_val, protocol, oracle, ocap, admin_cap) = setup(dev);
        let scenario = &mut scenario_val;
        let (bkt_treasury, bcap) = bkt::new_for_testing(test_utils::create_one_time_witness<BKT>(), test_scenario::ctx(scenario));
        let cumulative_fee_amount = 0;
        idx = 0;

        let coll = vector<u64>[3000, 1000, 800];
        let debt = vector<u64>[500, 800, 500];

        let oracle_price = 1000;
        bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);

        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, (idx as u64));
            test_scenario::next_tx(scenario, borrower);
            {
                let sui_input_amount = *vector::borrow(&coll, (idx as u64));
                let sui_input_amount = sui_input_amount * 1000000000;
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);

                let buck_output_amount = *vector::borrow(&debt, (idx as u64));
                let buck_output_amount = buck_output_amount * 1000000000;

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );

                let fee_amount = mul_factor(buck_output_amount, constants::min_fee(), constants::fee_precision());
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;
                assert!(balance::value(&buck_output) == buck_output_amount, 0);
                assert!(well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol)) == cumulative_fee_amount, 1);
                assert!(bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol)) == (idx as u64) + 1, 2);

                let tank = buck::borrow_tank_mut<SUI>(&mut protocol); 
                let token = tank::deposit(tank, buck_output, test_scenario::ctx(scenario));
                transfer::public_transfer(token, test_scenario::sender(scenario));

            };
            idx = idx + 1;
        };

        oracle_price = 800;
        bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);

        // borrower 2's CR: 125% -> 100% , liquidate
        test_scenario::next_tx(scenario, dev);
        {
            let debtor = bucket::get_lowest_cr_debtor(buck::borrow_bucket<SUI>(&protocol));
            if (option::is_none(&debtor)) {
                option::destroy_none(debtor);
            } else {
                let debtor = option::destroy_some(debtor);
                let liquidation_fee = buck::liquidate_under_normal_mode<SUI>(&mut protocol, &oracle, &clock, debtor);
                balance::destroy_for_testing<SUI>(liquidation_fee);
            };
        };

        // withdraw tank reward
        let borrower = *vector::borrow(&borrowers, 0);
        test_scenario::next_tx(scenario, borrower);
        {
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_withdrawal_amount = tank::get_token_weight(tank,&token);
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
            // test_utils::print(b"buck_output: ");
            let buck_output_amount = balance::value(&buck_output);
            // std::debug::print(&buck_output_amount);
            assert!(buck_output_amount == buck_withdrawal_amount, 0);
            // test_utils::print(b"sui_output: ");
            // std::debug::print(&balance::value(&sui_output));
            let bucket_size = bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol));
            // test_utils::print(b"bucket size: ");
            // std::debug::print(&bucket_size);
            assert!(bucket_size == 2, 0);

            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(sui_output);
        };


        test_scenario::next_tx(scenario, dev);
        {
            // test_utils::print(b"---------- Bottle Table Result ----------");
            bucket::check_bottle_order_in_bucket(buck::borrow_bucket<SUI>(&protocol), false);
        };

        buck::destroy_for_testing(admin_cap);
        clock::destroy_for_testing(clock);

        test_scenario::end(scenario_val);
        (protocol, oracle, ocap, bkt_treasury, bcap)
    }

    #[test]
    fun test_tank_empty_liquidate(): (BucketProtocol, BucketOracle, OracleAdminCap, BktTreasury, BktAdminCap) {

        let dev = @0xde1;
        let borrowers = vector<address>[];
        let borrower_count = 3;
        let idx = 1u8;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256((idx as u256) + 10));
            idx = idx + 1;
        };

        let (clock, scenario_val, protocol, oracle, ocap, admin_cap) = setup(dev);
        let scenario = &mut scenario_val;
        let (bkt_treasury, bcap) = bkt::new_for_testing(test_utils::create_one_time_witness<BKT>(), test_scenario::ctx(scenario));
        let cumulative_fee_amount = 0;
        idx = 0;

        let coll = vector<u64>[3000, 1000, 800];
        let debt = vector<u64>[500, 800, 500];
        let deposit_amount = vector<u64>[300, 200, 304];

        let oracle_price = 1000;
        bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);

        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, (idx as u64));
            test_scenario::next_tx(scenario, borrower);
            {
                let sui_input_amount = *vector::borrow(&coll, (idx as u64));
                let sui_input_amount = sui_input_amount * 1000000000;
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);

                let buck_output_amount = *vector::borrow(&debt, (idx as u64));
                let buck_output_amount = buck_output_amount * 1000000000;

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );

                let fee_amount = mul_factor(buck_output_amount, constants::min_fee(), constants::fee_precision());
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;
                assert!(balance::value(&buck_output) == buck_output_amount, 0);
                assert!(well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol)) == cumulative_fee_amount, 1);
                assert!(bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol)) == (idx as u64) + 1, 2);

                let buck_deposit_amount = *vector::borrow(&deposit_amount, (idx as u64));
                buck_deposit_amount = buck_deposit_amount * 1000000000;
                let buck_deposit = balance::split(&mut buck_output,buck_deposit_amount);
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol); 
                let token = tank::deposit(tank, buck_deposit, test_scenario::ctx(scenario));
                transfer::public_transfer(token, test_scenario::sender(scenario));

                balance::destroy_for_testing(buck_output);
            };
            idx = idx + 1;
        };

        oracle_price = 800;
        bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);

        // borrower 2's CR: 125% -> 100% , liquidate
        test_scenario::next_tx(scenario, dev);
        {
            let debtor = bucket::get_lowest_cr_debtor(buck::borrow_bucket<SUI>(&protocol));
            
            if (option::is_none(&debtor)) {
                option::destroy_none(debtor);
            } else {
                let debtor = option::destroy_some(debtor);
                let liquidation_fee = buck::liquidate_under_normal_mode<SUI>(&mut protocol, &oracle, &clock, debtor);
                balance::destroy_for_testing<SUI>(liquidation_fee);
            };
        };

        // withdraw tank reward
        let borrower = *vector::borrow(&borrowers, 0);
        test_scenario::next_tx(scenario, borrower);
        {
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_withdrawal_amount = tank::get_token_weight(tank,&token);
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
            // test_utils::print(b"buck_output: ");
            let buck_output_amount = balance::value(&buck_output);
            // std::debug::print(&buck_output_amount);
            assert!(buck_output_amount == buck_withdrawal_amount, 0);
            // test_utils::print(b"sui_output: ");
            // std::debug::print(&balance::value(&sui_output));
            let bucket_size = bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol));
            // test_utils::print(b"bucket size: ");
            // std::debug::print(&bucket_size);
            assert!(bucket_size == 2, 0);

            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(sui_output);
        };

        test_scenario::next_tx(scenario, dev);
        {
            // test_utils::print(b"---------- Bottle Table Result ----------");
            bucket::check_bottle_order_in_bucket(buck::borrow_bucket<SUI>(&protocol), false);
        };

        buck::destroy_for_testing(admin_cap);
        clock::destroy_for_testing(clock);

        test_scenario::end(scenario_val);
        (protocol, oracle, ocap, bkt_treasury, bcap)
    }

    #[test]
    // test liquidation succeeds after P reduced to 1
    fun test_p_reduced_to_one(): (BucketProtocol, BucketOracle, OracleAdminCap, BktTreasury, BktAdminCap) {

        let dev = @0xde1;
        let borrowers = vector<address>[];
        let borrower_count = 3;
        let idx = 1u8;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256((idx as u256) + 10));
            idx = idx + 1;
        };

        let (clock, scenario_val, protocol, oracle, ocap, admin_cap) = setup(dev);
        let scenario = &mut scenario_val;
        let (bkt_treasury, bcap) = bkt::new_for_testing(test_utils::create_one_time_witness<BKT>(), test_scenario::ctx(scenario));
        let cumulative_fee_amount = 0;
        idx = 0;

        let coll = vector<u64>[
            2000000000,
            2500000000,
            1000000000,
        ];
        let debt = vector<u64>[
            10000000,
            2000000000,
            500,
        ];
        let deposit_amount = vector<u64>[
            10000000,
            2000000000,
            1
        ];

        let oracle_price = 1000;
        bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);

        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, (idx as u64));
            test_scenario::next_tx(scenario, borrower);
            {
                let sui_input_amount = *vector::borrow(&coll, (idx as u64));
                let sui_input_amount = sui_input_amount * 1000000000;
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);

                let buck_output_amount = *vector::borrow(&debt, (idx as u64));
                let buck_output_amount = buck_output_amount * 1000000000;

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );

                let fee_amount = mul_factor(buck_output_amount, constants::min_fee(), constants::fee_precision());
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;

                let buck_deposit_amount = *vector::borrow(&deposit_amount, (idx as u64));
                buck_deposit_amount = buck_deposit_amount * 1000000000;
                if (idx == 1) {
                    let bal = coin::mint_for_testing<BUCK>(10000000*1000000000, test_scenario::ctx(scenario));
                    let coin = coin::into_balance(bal);
                    balance::join<BUCK>(&mut buck_output, coin);
                };
                let buck_deposit = balance::split(&mut buck_output,buck_deposit_amount);
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol); 
                let token = tank::deposit(tank, buck_deposit, test_scenario::ctx(scenario));
                transfer::public_transfer(token, test_scenario::sender(scenario));
                balance::destroy_for_testing(buck_output);
            };
            idx = idx + 1;
        };

        oracle_price = 800;
        bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);

        
        // borrower 2's CR: 125% -> 100% , liquidate
        test_scenario::next_tx(scenario, dev);
        {
            let debtor = bucket::get_lowest_cr_debtor(buck::borrow_bucket<SUI>(&protocol));
            
            if (option::is_none(&debtor)) {
                option::destroy_none(debtor);
            } else {
                let debtor = option::destroy_some(debtor);
                let liquidation_fee = buck::liquidate_under_normal_mode<SUI>(&mut protocol, &oracle, &clock, debtor);
                balance::destroy_for_testing<SUI>(liquidation_fee);
            };

            // let tank = buck::borrow_tank<SUI>(&protocol);
            // let p = tank::get_current_p<BUCK, SUI>(tank);
            // let epoch = tank::get_current_epoch<BUCK, SUI>(tank);
            // let scale = tank::get_current_scale<BUCK, SUI>(tank);
            
            // test_utils::print(b"tank.current_p");
            // std::debug::print(&p);
            // test_utils::print(b"tank.current_epoch");
            // std::debug::print(&epoch);
            // test_utils::print(b"tank.current_scale");
            // std::debug::print(&scale);
        };

        // withdraw tank reward
        let borrower = *vector::borrow(&borrowers, 2);
        test_scenario::next_tx(scenario, borrower);
        {
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_withdrawal_amount = tank::get_token_weight(tank,&token);
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
            // test_utils::print(b"buck_output: ");
            let buck_output_amount = balance::value(&buck_output);
            // std::debug::print(&buck_output_amount);
            assert!(buck_output_amount == buck_withdrawal_amount, 0);
            // test_utils::print(b"sui_output: ");
            // std::debug::print(&balance::value(&sui_output));
            let bucket_size = bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol));
            // test_utils::print(b"bucket size: ");
            // std::debug::print(&bucket_size);
            assert!(bucket_size == 2, 0);

            balance::destroy_for_testing(buck_output);
            balance::destroy_for_testing(sui_output);
        };


        test_scenario::next_tx(scenario, dev);
        {
            // test_utils::print(b"---------- Bottle Table Result ----------");
            bucket::check_bottle_order_in_bucket(buck::borrow_bucket<SUI>(&protocol), false);
        };

        buck::destroy_for_testing(admin_cap);
        clock::destroy_for_testing(clock);

        test_scenario::end(scenario_val);
        (protocol, oracle, ocap, bkt_treasury, bcap)
    }    
}