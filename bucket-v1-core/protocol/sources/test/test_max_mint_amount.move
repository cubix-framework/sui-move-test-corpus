#[test_only]
module bucket_protocol::test_buck_admin {
    use sui::sui::SUI;
    use sui::balance;
    use sui::clock::Clock;
    use sui::test_scenario;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::buck::{Self, BucketProtocol, AdminCap};
    use bucket_protocol::bucket;
    use bucket_protocol::test_utils::{setup_randomly, dev};

    #[test]
    #[expected_failure(abort_code = bucket::ECannotExceedMintCap)]
    fun test_cannot_exceed_max_mint_amount() {
        let oracle_price = 1_120;
        let borrower_count = 39;
        let (scenario_val, _) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let added_mint_amount: u64 = 1_234_567_890_000;
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(std::option::is_none(&bucket::get_max_mint_amount(bucket)), 0);
            let bucket_minted_amount = bucket::get_minted_buck_amount(bucket);
            buck::update_max_mint_amount<SUI>(&admin_cap, &mut protocol, std::option::some(bucket_minted_amount + added_mint_amount));
            test_scenario::return_shared(protocol);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        let borrower = @0xa11e0;
        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let sui_input_amount = 9_000_000_000_000;
            let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
            let buck_output_amount = added_mint_amount + 1;
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_within_max_mint_amount() {
        let oracle_price = 1_120;
        let borrower_count = 39;
        let (scenario_val, _) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let added_mint_amount: u64 = 1_234_567_890_000;
        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(std::option::is_none(&bucket::get_max_mint_amount(bucket)), 0);
            let bucket_minted_amount = bucket::get_minted_buck_amount(bucket);
            buck::update_max_mint_amount<SUI>(&admin_cap, &mut protocol, std::option::some(bucket_minted_amount + added_mint_amount));
            test_scenario::return_shared(protocol);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        let borrower = @0xa11e0;
        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let sui_input_amount = 9_000_000_000_000;
            let sui_input = balance::create_for_testing<SUI>(sui_input_amount);
            let buck_output_amount = added_mint_amount * 1000 / 1005;
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(buck_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }
}