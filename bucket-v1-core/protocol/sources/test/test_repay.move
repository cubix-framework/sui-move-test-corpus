#[test_only]
module bucket_protocol::test_repay {
    use std::vector;
    use sui::balance;
    use sui::sui::SUI;
    use sui::test_scenario;
    use sui::clock::Clock;
    use bucket_framework::math::mul_factor;
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::test_utils;
    use bucket_protocol::bottle;

    #[test]
    fun test_repay() {
        let oracle_price = 770;
        let user_count: u8 = 20;
        let (scenario_val, users) = test_utils::setup_randomly(oracle_price, user_count);
        let scenario = &mut scenario_val;

        let idx: u8 = 0;
        while (idx < user_count) {
            let user = *vector::borrow(&users, (idx as u64));
            // std::debug::print(&idx);
            if (idx % 2 == 0) {
                // fully repay
                test_scenario::next_tx(scenario, user);
                {
                    let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                    let clock = test_scenario::take_shared<Clock>(scenario);
                    let (collateral_amount, debt_amount) = buck::get_bottle_info_with_interest_by_debtor<SUI>(&protocol, user, &clock);
                    let buck_input = balance::create_for_testing<BUCK>(debt_amount);
                    let collateral_return = buck::repay_debt<SUI>(&mut protocol, buck_input, &clock, test_scenario::ctx(scenario));
                    assert!(balance::value(&collateral_return) == collateral_amount, 0);
                    balance::destroy_for_testing(collateral_return);
                    test_scenario::return_shared(protocol);
                    test_scenario::return_shared(clock);
                };
                
                test_scenario::next_tx(scenario, user);
                {
                    let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                    let bucket = buck::borrow_bucket<SUI>(&protocol);
                    assert!(!bucket::bottle_exists(bucket, user), 0);
                    assert!(bucket::check_bottle_order_in_bucket(bucket, false) == ((user_count - idx/2 - 1) as u64), 0);
                    test_scenario::return_shared(protocol);
                };                
            } else {
                // partially repay
                test_scenario::next_tx(scenario, user);
                {
                    let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                    let clock = test_scenario::take_shared<Clock>(scenario);
                    let (collateral_amount, debt_amount) = buck::get_bottle_info_with_interest_by_debtor<SUI>(&protocol, user, &clock);
                    let min_bottle_size = buck::get_min_bottle_size(&protocol);
                    let repay_amount = debt_amount - min_bottle_size;
                    let buck_input = balance::create_for_testing<BUCK>(repay_amount);
                   
                    let expected_collateral_amount = mul_factor(collateral_amount, repay_amount, debt_amount);
                    let collateral_return = buck::repay_debt<SUI>(&mut protocol, buck_input, &clock, test_scenario::ctx(scenario));
                    assert!(balance::value(&collateral_return) == expected_collateral_amount, 0);
                    balance::destroy_for_testing(collateral_return);
                    test_scenario::return_shared(protocol);
                    test_scenario::return_shared(clock);
                };
                
                test_scenario::next_tx(scenario, user);
                {
                    let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
                    let bucket = buck::borrow_bucket<SUI>(&protocol);
                    assert!(bucket::bottle_exists(bucket, user), 0);
                    assert!(bucket::check_bottle_order_in_bucket(bucket, false) == ((user_count - idx/2 - 1) as u64), 0);
                    test_scenario::return_shared(protocol);
                };
            };
            idx = idx + 1;
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bottle::EBottleTooSmall)]
    fun test_repay_bottle_too_small() {
        let oracle_price = 770;
        let user_count: u8 = 20;
        let (scenario_val, users) = test_utils::setup_randomly(oracle_price, user_count);
        let scenario = &mut scenario_val;

        let debtor = *vector::borrow(&users, 10);
        test_scenario::next_tx(scenario, debtor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let min_bottle_size = buck::get_min_bottle_size(&protocol);
            let (_, debt_amount) = buck::get_bottle_info_with_interest_by_debtor<SUI>(&protocol, debtor, &clock);
            let repay_amount = debt_amount - min_bottle_size + 1;
            let buck_input = balance::create_for_testing<BUCK>(repay_amount);
            let collateral_return = buck::repay_debt<SUI>(&mut protocol, buck_input, &clock, test_scenario::ctx(scenario));
            balance::destroy_for_testing(collateral_return);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::ERepayTooMuch)]
    fun test_repay_too_much() {
        let oracle_price = 880;
        let user_count: u8 = 23;
        let (scenario_val, users) = test_utils::setup_randomly(oracle_price, user_count);
        let scenario = &mut scenario_val;
        let debtor = *vector::borrow(&users, 13);
        test_scenario::next_tx(scenario, debtor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let (_, debt_amount) = buck::get_bottle_info_with_interest_by_debtor<SUI>(&protocol, debtor, &clock);
            let repay_amount = debt_amount + 1;
            let buck_input = balance::create_for_testing<BUCK>(repay_amount);
            let collateral_return = buck::repay_debt<SUI>(&mut protocol, buck_input, &clock, test_scenario::ctx(scenario));
            balance::destroy_for_testing(collateral_return);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
        };
        
        test_scenario::end(scenario_val);
    }
}