#[test_only]
module bucket_protocol::test_utils {
    use std::u64::diff;
    use sui::balance;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, Scenario};
    use sui::test_utils;
    use sui::test_random;
    use sui::address;
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use std::vector;
    use std::option;

    use bucket_framework::math::mul_factor;
    use bucket_protocol::well;
    use bucket_protocol::bucket::{Self, bottle_exists};
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol, borrow_bucket};
    use bucket_protocol::bkt::{Self, BKT, BktTreasury};
    use bucket_oracle::bucket_oracle::{Self, BucketOracle};
    use bucket_protocol::constants;
    use bucket_protocol::tank::{Self, ContributorToken};

    const DEV_ADDRESS: address = @0xf37e3b400f87b40265065c0c2651c74234dc5bea46e3853e2cd95914f34b537c;
    const START_TIMESTAMP: u64 = 1687881600000;
    const MAX_STAKE_AMOUNT: u64 = 72057594037927936; // 2^56

    const ESetupAmountsNotMatch: u64 = 0;

    #[test_only]
    public fun dev(): address { DEV_ADDRESS }

    #[test_only]
    public fun start_time(): u64 { START_TIMESTAMP }

    #[test_only]
    public fun setup_empty(oracle_price: u64): Scenario {
        let dev = DEV_ADDRESS;
        let scenario_val = test_scenario::begin(dev);
        let scenario = &mut scenario_val;

        let clock = clock::create_for_testing(test_scenario::ctx(scenario));
        clock::set_for_testing(&mut clock, START_TIMESTAMP);
        clock::share_for_testing(clock);
        buck::share_for_testing( test_utils::create_one_time_witness<BUCK>(), dev, test_scenario::ctx(scenario));
        bucket_oracle::share_for_testing<SUI>(3, dev, test_scenario::ctx(scenario));        
        bkt::share_for_testing(test_utils::create_one_time_witness<BKT>(), dev, test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, dev);
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);
            test_scenario::return_shared(oracle);
        };

        scenario_val
    }

    #[test_only]
    public fun setup_empty_with_interest(oracle_price: u64): Scenario {
        let dev = DEV_ADDRESS;
        let scenario_val = test_scenario::begin(dev);
        let scenario = &mut scenario_val;

        let clock = clock::create_for_testing(test_scenario::ctx(scenario));
        clock::set_for_testing(&mut clock, START_TIMESTAMP);
        buck::share_for_testing_with_interest( test_utils::create_one_time_witness<BUCK>(), dev, &clock, test_scenario::ctx(scenario));
        clock::share_for_testing(clock);
        bucket_oracle::share_for_testing<SUI>(3, dev, test_scenario::ctx(scenario));        
        bkt::share_for_testing(test_utils::create_one_time_witness<BKT>(), dev, test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, dev);
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);
            test_scenario::return_shared(oracle);
        };

        scenario_val
    }

    #[test_only]
    public fun setup_empty_with_decimals(oracle_price: u64, decimals: u8): Scenario {
        let dev = DEV_ADDRESS;
        let scenario_val = test_scenario::begin(dev);
        let scenario = &mut scenario_val;

        let clock = clock::create_for_testing(test_scenario::ctx(scenario));
        clock::set_for_testing(&mut clock, START_TIMESTAMP);
        clock::share_for_testing(clock);
        buck::share_for_testing(test_utils::create_one_time_witness<BUCK>(), dev, test_scenario::ctx(scenario));
        bucket_oracle::share_for_testing<SUI>(decimals, dev, test_scenario::ctx(scenario));        
        bkt::share_for_testing(test_utils::create_one_time_witness<BKT>(), dev, test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, dev);
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            bucket_oracle::update_price_for_testing<SUI>(&mut oracle, oracle_price);
            test_scenario::return_shared(oracle);
        };

        scenario_val
    }

    #[test_only]
    public fun setup_randomly(oracle_price: u64, borrower_count: u8): (Scenario, vector<address>) {

        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        let seed = b"bucket protocol borrowers";
        vector::push_back(&mut seed, borrower_count);
        let rang = test_random::new(seed);
        let rangr = &mut rang;

        let borrowers = vector<address>[];
        let idx = 1u8;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256(test_random::next_u256(rangr)));
            idx = idx + 1;
        };

        let cumulative_fee_amount = 0;
        let fee_precision = constants::fee_precision();
        let borrow_fee_rate = constants::min_fee();
        let idx: u8 = 0;
        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, (idx as u64));
            test_scenario::next_tx(scenario, borrower);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let minimal_bottle_size = buck::get_min_bottle_size(&protocol);
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);

                let buck_output_amount = minimal_bottle_size + test_random::next_u64(rangr) % (minimal_bottle_size * 10000);

                let collateral_ratio = 120 + test_random::next_u64(rangr) % 500;

                let sui_input_amount = mul_factor(buck_output_amount, collateral_ratio, 100);
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );
                let fee_amount = mul_factor(buck_output_amount, borrow_fee_rate, fee_precision);
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;
                assert!(balance::value(&buck_output) == buck_output_amount, 0);
                assert!(well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol)) == cumulative_fee_amount, 0);
                assert!(bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol)) == (idx as u64) + 1, 0);
                balance::destroy_for_testing(buck_output);
 
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
            };
            idx = idx + 1;
        };

        (scenario_val, borrowers)
    }

    #[test_only]
    public fun setup_randomly_with_interest(oracle_price: u64, borrower_count: u8): (Scenario, vector<address>) {

        let scenario_val = setup_empty_with_interest(oracle_price);
        let scenario = &mut scenario_val;

        let seed = b"bucket protocol borrowers";
        vector::push_back(&mut seed, borrower_count);
        let rang = test_random::new(seed);
        let rangr = &mut rang;

        let borrowers = vector<address>[];
        let idx = 1u8;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256(test_random::next_u256(rangr)));
            idx = idx + 1;
        };

        let cumulative_fee_amount = 0;
        let fee_precision = constants::fee_precision();
        let borrow_fee_rate = constants::min_fee();
        let idx: u8 = 0;
        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, (idx as u64));
            test_scenario::next_tx(scenario, borrower);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let minimal_bottle_size = buck::get_min_bottle_size(&protocol);
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);

                let buck_output_amount = minimal_bottle_size + test_random::next_u64(rangr) % (minimal_bottle_size * 10000);

                let collateral_ratio = 120 + test_random::next_u64(rangr) % 500;

                let sui_input_amount = mul_factor(buck_output_amount, collateral_ratio, 100);
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );
                let fee_amount = mul_factor(buck_output_amount, borrow_fee_rate, fee_precision);
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;
                assert!(balance::value(&buck_output) == buck_output_amount, 0);
                assert!(well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol)) == cumulative_fee_amount, 0);
                assert!(bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol)) == (idx as u64) + 1, 0);
                balance::destroy_for_testing(buck_output);
 
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
            };
            idx = idx + 1;
        };

        (scenario_val, borrowers)
    }

    #[test_only]
    public fun setup_customly_with_decimals(
        oracle_price: u64,
        decimals: u8,
        collateral_amounts: vector<u64>,
        debt_amounts: vector<u64>,
    ): (Scenario, vector<address>) {
        let borrower_count = vector::length(&collateral_amounts);
        assert!(borrower_count == vector::length(&debt_amounts), ESetupAmountsNotMatch);
    
        let scenario_val = setup_empty_with_decimals(oracle_price, decimals);
        let scenario = &mut scenario_val;
    
        let borrowers = vector<address>[];
        let idx: u64 = 1;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256((idx as u256)));
            idx = idx + 1;
        };

        let cumulative_fee_amount = 0;
        let fee_precision = constants::fee_precision();
        let borrow_fee_rate = constants::min_fee();
        let idx: u64 = 0;
        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, idx);
            test_scenario::next_tx(scenario, borrower);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);

                let sui_input_amount = *vector::borrow(&collateral_amounts, idx);
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
                let buck_output_amount = *vector::borrow(&debt_amounts, idx);

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );
                let fee_amount = mul_factor(buck_output_amount, borrow_fee_rate, fee_precision);
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;
                assert!(balance::value(&buck_output) == buck_output_amount, 0);
                assert!(well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol)) == cumulative_fee_amount, 0);
                assert!(bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol)) == (idx as u64) + 1, 0);
                balance::destroy_for_testing(buck_output);
 
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
            };
            idx = idx + 1;
        };

        (scenario_val, borrowers)
    }
    #[test_only]
    public fun setup_customly(
        oracle_price: u64,
        collateral_amounts: vector<u64>,
        debt_amounts: vector<u64>,
    ): (Scenario, vector<address>) {
        let borrower_count = vector::length(&collateral_amounts);
        assert!(borrower_count == vector::length(&debt_amounts), ESetupAmountsNotMatch);
    
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;
    
        let borrowers = vector<address>[];
        let idx: u64 = 1;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256((idx as u256)));
            idx = idx + 1;
        };

        let cumulative_fee_amount = 0;
        let fee_precision = constants::fee_precision();
        let borrow_fee_rate = constants::min_fee();
        let idx: u64 = 0;
        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, idx);
            test_scenario::next_tx(scenario, borrower);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);

                let sui_input_amount = *vector::borrow(&collateral_amounts, idx);
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
                let buck_output_amount = *vector::borrow(&debt_amounts, idx);

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );
                let fee_amount = mul_factor(buck_output_amount, borrow_fee_rate, fee_precision);
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;
                assert!(balance::value(&buck_output) == buck_output_amount, 0);
                assert!(well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol)) == cumulative_fee_amount, 0);
                assert!(bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol)) == (idx as u64) + 1, 0);
                balance::destroy_for_testing(buck_output);
 
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
            };
            idx = idx + 1;
        };

        (scenario_val, borrowers)
    }

    #[test_only]
    public fun setup_customly_with_interest(
        oracle_price: u64,
        collateral_amounts: vector<u64>,
        debt_amounts: vector<u64>,
    ): (Scenario, vector<address>) {
        let borrower_count = vector::length(&collateral_amounts);
        assert!(borrower_count == vector::length(&debt_amounts), ESetupAmountsNotMatch);
    
        let scenario_val = setup_empty_with_interest(oracle_price);
        let scenario = &mut scenario_val;
    
        let borrowers = vector<address>[];
        let idx: u64 = 1;
        while (idx <= borrower_count) {
            vector::push_back(&mut borrowers, address::from_u256((idx as u256)));
            idx = idx + 1;
        };

        let cumulative_fee_amount = 0;
        let fee_precision = constants::fee_precision();
        let borrow_fee_rate = constants::min_fee();
        let idx: u64 = 0;
        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, idx);
            test_scenario::next_tx(scenario, borrower);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);

                let sui_input_amount = *vector::borrow(&collateral_amounts, idx);
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
                let buck_output_amount = *vector::borrow(&debt_amounts, idx);

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );
                let fee_amount = mul_factor(buck_output_amount, borrow_fee_rate, fee_precision);
                cumulative_fee_amount = cumulative_fee_amount + fee_amount;
                assert!(balance::value(&buck_output) == buck_output_amount, 0);
                assert!(well::get_well_reserve_balance(buck::borrow_well<BUCK>(&protocol)) == cumulative_fee_amount, 0);
                assert!(bucket::get_bottle_table_length(buck::borrow_bucket<SUI>(&protocol)) == (idx as u64) + 1, 0);
                balance::destroy_for_testing(buck_output);
 
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
            };
            idx = idx + 1;
        };

        (scenario_val, borrowers)
    }

    #[test_only]
    public fun approx_equal(value_1: u64, value_2: u64, deviation: u64): bool {
        diff(value_1, value_2) <= deviation
    }

    #[test_only]
    public fun get_coin_amount_times_decimal(coin: vector<u64>, decimal_factor: u64): vector<u64> {
        let result = vector<u64>[];
        let idx: u64 = 0;
        while (idx < vector::length(&coin)) {
            let value = *vector::borrow(&coin, idx);
            vector::push_back(&mut result, value * decimal_factor);
            idx = idx + 1;
        };
        result
    }

    #[test_only]
    public fun calculate_collateral_amount_by_icr(debt_amounts: vector<u64>, icr: vector<u64>, oracle_price: u64, denominator: u64): vector<u64> {
        let collateral_amount = vector<u64>[];
        let idx: u64 = 0;
        while (idx < vector::length(&debt_amounts)) {
            let debt_amount = *vector::borrow(&debt_amounts, idx);
            let icr = *vector::borrow(&icr, idx);
            let coll = mul_factor(debt_amount * icr , denominator, oracle_price * 100);
            vector::push_back(&mut collateral_amount, coll);
            idx = idx + 1;
        };
        collateral_amount
    }   

    #[test_only]
    public fun open_bottle_by_icr(
        debt_amounts: vector<u64>,
        icr: vector<u64>,
        borrowers: vector<address>,
        scenario: &mut Scenario,
    ) {
        let borrower_count = vector::length(&debt_amounts);
        assert!(borrower_count == vector::length(&icr), ESetupAmountsNotMatch);
        assert!(borrower_count == vector::length(&borrowers), ESetupAmountsNotMatch);

        let collateral_amounts = vector<u64>[];

        test_scenario::next_tx(scenario, dev());
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let (price, denominator) = bucket_oracle::get_price<SUI>(&oracle, &clock);
            vector::append(&mut collateral_amounts, calculate_collateral_amount_by_icr(debt_amounts, icr, price, denominator));
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        let idx: u64 = 0;
        while (idx < borrower_count) {
            let borrower = *vector::borrow(&borrowers, idx);
            test_scenario::next_tx(scenario, borrower);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);
                let sui_input_amount = *vector::borrow(&collateral_amounts, idx);
                let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
                let buck_output_amount = *vector::borrow(&debt_amounts, idx);

                let buck_output = buck::borrow(
                    &mut protocol,
                    &oracle,
                    &clock,
                    sui_input,
                    buck_output_amount,
                    option::none(),
                    test_scenario::ctx(scenario),
                );        
                balance::destroy_for_testing(buck_output);
 
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
            };
            idx = idx + 1;
        };
        
    }

    #[test_only]
    public fun stake_randomly<T>(scenario: &mut Scenario, staker_count: u8): vector<address> {
        let seed = b"bucket protocol stakers";
        vector::push_back(&mut seed, staker_count);
        let rang = test_random::new(seed);
        let rangr = &mut rang;

        let stakers = vector<address>[];
        let idx = 1u8;
        while (idx <= staker_count) {
            vector::push_back(&mut stakers, address::from_u256(test_random::next_u256(rangr)));
            idx = idx + 1;
        };

        let total_stake_amount: u64 = 0;
        let total_stake_weight: u64 = 0;
        let idx: u8 = 0;
        let lock_time_range = constants::max_lock_time() - constants::min_lock_time();
        while (idx < staker_count) {
            let staker = *vector::borrow(&stakers, (idx as u64));
            test_scenario::next_tx(scenario, staker);
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);

                let stake_amount = test_random::next_u64_in_range(rangr, MAX_STAKE_AMOUNT);
                if (stake_amount == 0) stake_amount = 1_000_000;
                let lock_time = constants::min_lock_time() + test_random::next_u64_in_range(rangr, lock_time_range);

                let bkt_input = balance::create_for_testing<BKT>(stake_amount);

                let well = buck::borrow_well_mut<T>(&mut protocol);
                let st_bkt = well::stake(&clock, well, bkt_input, lock_time, test_scenario::ctx(scenario));

                assert!(well::get_token_lock_until(&st_bkt) == start_time() + lock_time, 0);
                assert!(well::get_token_stake_amount(&st_bkt) == stake_amount, 0);
                let expected_token_stake_weight = mul_factor(stake_amount, lock_time, constants::max_lock_time());
                assert!(well::get_token_stake_weight(&st_bkt) == expected_token_stake_weight, 0);
                total_stake_amount = total_stake_amount + stake_amount;
                assert!(well::get_well_staked_balance(well) == total_stake_amount, 0);
 
                total_stake_weight = total_stake_weight + expected_token_stake_weight;
                assert!(well::get_well_total_weight(well) == total_stake_weight, 0);

                transfer::public_transfer(st_bkt, staker);
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(clock);
            };
            idx = idx + 1;
        };

        stakers
    }

    #[test_only]
    public fun set_coll_price(scenario: &mut Scenario, price: u64) {
        test_scenario::next_tx(scenario, dev());
        {
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            bucket_oracle::update_price_for_testing<SUI>(&mut oracle, price);
            test_scenario::return_shared(oracle);
        };
    }

    #[test_only]
    public fun liquidate_normal_mode(scenario: &mut Scenario, debtor: address) {
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);

            // check not in recovery mode
            let bucket = borrow_bucket<SUI>(&protocol);
            assert!(!bucket::is_in_recovery_mode(bucket, &oracle, &clock), 1);
            
            let liquidation_fee = 
                buck::liquidate_under_normal_mode<SUI>(
                    &mut protocol, 
                    &oracle, 
                    &clock, 
                    debtor
                );
            balance::destroy_for_testing<SUI>(liquidation_fee);

            // check the bottle is closed
            let bucket = borrow_bucket<SUI>(&protocol);
            assert!(!bottle_exists(bucket, debtor), 1);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };
    }

    #[test_only]
    public fun liquidate_recovery_mode(scenario: &mut Scenario, debtor: address) {
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);

            // check not in recovery mode
            let bucket = borrow_bucket<SUI>(&protocol);
            assert!(bucket::is_in_recovery_mode(bucket, &oracle, &clock), 1);
            
            let liquidation_fee = 
                buck::liquidate_under_recovery_mode<SUI>(
                    &mut protocol, 
                    &oracle, 
                    &clock, 
                    debtor
                );
            balance::destroy_for_testing<SUI>(liquidation_fee);

            // check the bottle is closed
            // let bucket = borrow_bucket<SUI>(&protocol);
            // assert!(!bottle_exists(bucket, debtor), 1);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };
    }

    #[test_only]
    public fun check_bottle_info(
        scenario: &mut Scenario, 
        debtor: address, 
        expected_coll: u64, 
        expected_debt: u64
    ) {
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = borrow_bucket<SUI>(&protocol);
            let (coll_amount, debt_amount) = bucket::get_bottle_info_by_debtor(bucket, debtor);
            // std::debug::print(&coll_amount);
            // std::debug::print(&debt_amount);
            assert!(approx_equal(coll_amount, expected_coll, 10), 1);
            assert!(approx_equal(debt_amount, expected_debt, 10), 1);
            test_scenario::return_shared(protocol);
        };
    }

    #[test_only]
    public fun check_surplus_bottle_info(
        scenario: &mut Scenario, 
        debtor: address, 
        expected_coll: u64, 
        expected_debt: u64
    ) {
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = borrow_bucket<SUI>(&protocol);
            let (coll_amount, debt_amount) = bucket::get_surplus_bottle_info_by_debtor(bucket, debtor);
            // std::debug::print(&coll_amount);
            assert!(approx_equal(coll_amount, expected_coll, 10), 1);
            assert!(approx_equal(debt_amount, expected_debt, 10), 1);
            test_scenario::return_shared(protocol);
        };
    }

    #[test_only]
    public fun deposit_buck_to_tank(
        scenario: &mut Scenario,
        depositors: vector<address>,
        deposit_amount: vector<u64>
    ) {
        let idx: u64 = 0;
        while (idx < vector::length(&deposit_amount)) {    
            test_scenario::next_tx(scenario, *vector::borrow(&depositors, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let buck_input = balance::create_for_testing<BUCK>(*vector::borrow(&deposit_amount, idx));
                let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                let token = tank::deposit<BUCK, SUI>(tank, buck_input, test_scenario::ctx(scenario));
                
                transfer::public_transfer(token, test_scenario::sender(scenario));
                test_scenario::return_shared<BucketProtocol>(protocol);
            };
            idx = idx + 1;
        };
    }

    #[test_only]
    public fun withdraw_buck_from_tank(
        scenario: &mut Scenario,
        withdrawers: vector<address>
    ) {
        let idx: u64 = 0;
        while (idx < vector::length(&withdrawers)) {    
            test_scenario::next_tx(scenario, *vector::borrow(&withdrawers, idx));
            {
                let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                let oracle = test_scenario::take_shared<BucketOracle>(scenario);
                let clock = test_scenario::take_shared<Clock>(scenario);
                let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
                let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
                let _tank = buck::borrow_tank_mut<SUI>(&mut protocol);
                // let buck_withdrawal_amount = tank::get_token_weight(tank,&token);
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
                balance::destroy_for_testing(sui_output);
                balance::destroy_for_testing(bkt_reward);
                
                test_scenario::return_shared(protocol);
                test_scenario::return_shared(oracle);
                test_scenario::return_shared(clock);
                test_scenario::return_shared(bkt_treasury);
                
            };
            idx = idx + 1;
        };
    }
}
