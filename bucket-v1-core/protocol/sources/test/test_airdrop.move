#[test_only]
module bucket_protocol::test_airdrop {
    use sui::sui::SUI;
    use sui::balance;
    use sui::test_scenario;
    use bucket_protocol::buck::{Self, BucketProtocol};
    use bucket_protocol::tank;
    use bucket_protocol::test_utils::{setup_empty, dev};

    #[test]
    fun test_airdrop() {
        let oracle_price = 3456;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            tank::airdrop_collateral(tank, balance::create_for_testing(99));
            tank::airdrop_bkt(tank, balance::create_for_testing(66));
            test_scenario::return_shared(protocol);
        };

        test_scenario::next_tx(scenario, dev());
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank<SUI>(&protocol);
            assert!(tank::get_collateral_pool_balance(tank) == 99, 0);
            assert!(tank::get_bkt_pool_balance(tank) == 66, 0);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }
}