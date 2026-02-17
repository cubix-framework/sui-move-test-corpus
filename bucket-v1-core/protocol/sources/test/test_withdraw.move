#[test_only]
module bucket_protocol::test_withdraw {

    use std::vector;
    use sui::balance;
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::clock::Clock;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::buck::{Self, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::test_utils::setup_customly;

    #[test]
    #[expected_failure(abort_code = bucket::EBottleIsNotHealthy)]
    fun test_withdraw_cause_unhealthy() {
        let oracle_price: u64 = 2_000;
        let coll_amount = vector[30_000_000_000, 1000_000_000_000];
        let debt_amount = vector[30_000_000_000, 10_000_000_000];
        let (scenario_val, borrowers) = setup_customly(oracle_price, coll_amount, debt_amount);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let sui_withdrawal_amount = 14_000_000_000;
            let sui_output = buck::withdraw<SUI>(&mut protocol, &oracle, &clock, sui_withdrawal_amount, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(sui_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::EBottleIsNotHealthy)]
    fun test_withdraw_cause_recovery_mode_unhealthy() {
        let oracle_price: u64 = 2_000;
        let coll_amount = vector[30_000_000_000, 20_000_000_000];
        let debt_amount = vector[30_000_000_000, 30_000_000_000];
        let (scenario_val, borrowers) = setup_customly(oracle_price, coll_amount, debt_amount);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, *vector::borrow(&borrowers, 0));
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let sui_withdrawal_amount = 6_000_000_000;
            let sui_output = buck::withdraw<SUI>(&mut protocol, &oracle, &clock, sui_withdrawal_amount, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(sui_output);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario_val);
    }

}