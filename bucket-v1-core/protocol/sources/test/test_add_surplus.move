#[test_only]
module bucket_protocol::test_add_surplus {
    use sui::sui::SUI;
    use sui::balance;
    use sui::test_scenario as ts;
    use sui::transfer;
    use bucket_protocol::test_utils::{setup_empty_with_interest, dev};
    use bucket_protocol::buck::{Self, BucketProtocol};
    use bucket_protocol::strap::{Self, BottleStrap};
    use bucket_protocol::bucket;

    #[test]
    fun test_add_surplus() {
        let oracle_price = 6666;
        let scenario_val = setup_empty_with_interest(oracle_price);
        let s = &mut scenario_val;

        let amount_in = 1_000_000_000_0000; // 1000 SUI
        ts::next_tx(s, dev());
        let strap_addr = {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let strap = strap::new<SUI>(ts::ctx(s));
            let strap_addr = strap::get_address(&strap);
            let collateral = balance::create_for_testing<SUI>(amount_in);
            buck::deposit_surplus_with_strap(&mut protocol, collateral, &strap, ts::ctx(s));
            transfer::public_transfer(strap, dev());
            ts::return_shared(protocol);
            strap_addr
        };

        let amount_out = 777_000_000_000;
        let remaining_amount = amount_in - amount_out;
        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(s);
            
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (coll_amount, debt_amount) = bucket::get_surplus_bottle_info_by_debtor(bucket, strap_addr);
            assert!(coll_amount == amount_in, 0);
            assert!(debt_amount == 0, 0);
            assert!(bucket::get_surplus_bottle_table_size(bucket) == 1, 0);
            assert!(bucket::get_surplus_collateral_amount(bucket, strap_addr) == amount_in, 0);

            let surplus = buck::withdraw_surplus_with_strap(&mut protocol, &strap);
            assert!(balance::value(&surplus) == amount_in, 0);
            let out = balance::split(&mut surplus, amount_out);
            balance::destroy_for_testing(out);
            buck::deposit_surplus_with_strap(&mut protocol, surplus, &strap, ts::ctx(s));

            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (coll_amount, debt_amount) = bucket::get_surplus_bottle_info_by_debtor(bucket, strap_addr);
            assert!(coll_amount == remaining_amount, 0);
            assert!(debt_amount == 0, 0);
            assert!(bucket::get_surplus_bottle_table_size(bucket) == 1, 0);
            assert!(bucket::get_surplus_collateral_amount(bucket, strap_addr) == remaining_amount, 0);

            ts::return_to_sender(s, strap);
            ts::return_shared(protocol);
        };

        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(s);

            let surplus = buck::withdraw_surplus_with_strap(&mut protocol, &strap);
            assert!(balance::value(&surplus) == remaining_amount, 0);
            balance::destroy_for_testing(surplus);

            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(bucket::get_surplus_bottle_table_size(bucket) == 0, 0);

            ts::return_to_sender(s, strap);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }
}