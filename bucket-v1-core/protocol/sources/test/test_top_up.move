#[test_only]
module bucket_protocol::test_top_up {
    use std::vector;
    use sui::sui::SUI;
    use sui::balance;
    use sui::test_scenario;
    use sui::clock::Clock;
    use bucket_protocol::buck::{Self, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::test_utils::{setup_randomly};

    #[test]
    fun test_top_up() {
        let oracle_price: u64 = 990;
        let borrower_count: u8 = 12;
        let (scenario_val, borrowers) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let borrower = *vector::borrow(&borrowers, 6);
        let sponser = @0x6666;
        let top_up_amount: u64 = 666_666_666_666;
        test_scenario::next_tx(scenario, sponser);
        let (sui_amount_before, buck_amount_before) = {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let (sui_amount_before, buck_amount_before) = buck::get_bottle_info_by_debtor<SUI>(&protocol, borrower);
            let sui_input = balance::create_for_testing<SUI>(top_up_amount);
            buck::top_up_coll<SUI>(&mut protocol, sui_input, borrower, std::option::none(), &clock);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(clock);
            (sui_amount_before, buck_amount_before)
        };

        test_scenario::next_tx(scenario, borrower);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let (sui_amount_after, buck_amount_after) = buck::get_bottle_info_by_debtor<SUI>(&protocol, borrower);
            assert!(sui_amount_after == sui_amount_before + top_up_amount, 0);
            assert!(buck_amount_after == buck_amount_before, 0);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            bucket::check_bottle_order_in_bucket(bucket, false);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }
}