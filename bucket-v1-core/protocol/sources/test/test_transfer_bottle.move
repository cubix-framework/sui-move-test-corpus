#[test_only]
module bucket_protocol::test_transfer_bottle {

    use std::vector;
    use std::option;
    use sui::balance;
    use sui::test_scenario as ts;
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::transfer;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::buck::{Self, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::strap::{Self, BottleStrap};
    use bucket_protocol::test_utils::setup_customly_with_interest;

    #[test]
    fun test_transfer_bottle() {
        let oracle_price: u64 = 2_000;
        let coll_amount = vector[1000_000_000_000, 30_000_000_000, ];
        let debt_amount = vector[10_000_000_000, 30_000_000_000];
        let (scenario_val, borrowers) = setup_customly_with_interest(oracle_price, coll_amount, debt_amount);
        let scenario = &mut scenario_val;
        
        let new_debtor = @0xabcdef;

        let old_debtor_0 = *vector::borrow(&borrowers, 0);
        ts::next_tx(scenario, old_debtor_0);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            // let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = strap::new<SUI>(ts::ctx(scenario));
            let strap_addr = strap::get_address(&strap);
            buck::transfer_bottle<SUI>(&mut protocol, &clock, strap_addr, ts::ctx(scenario));
            transfer::public_transfer(strap, new_debtor);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(!bucket::bottle_exists(bucket, old_debtor_0), 0);
            assert!(bucket::bottle_exists(bucket, strap_addr), 0);
            ts::return_shared(protocol);
            // ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        let old_debtor_1 = *vector::borrow(&borrowers, 1);
        ts::next_tx(scenario, old_debtor_1);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            // let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            buck::transfer_bottle<SUI>(&mut protocol, &clock, new_debtor, ts::ctx(scenario));
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(!bucket::bottle_exists(bucket, old_debtor_0), 0);
            assert!(bucket::bottle_exists(bucket, new_debtor), 0);
            ts::return_shared(protocol);
            // ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, new_debtor);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);
            let coll_in = balance::create_for_testing<SUI>(5_000_000_000);
            let borrow_amount = 5_000_000_000;
            let buck_out = buck::borrow_with_strap(
                &mut protocol, &oracle, &strap, &clock, coll_in, borrow_amount, option::none(), ts::ctx(scenario),
            );
            let coll_out = buck::repay_debt<SUI>(&mut protocol, buck_out, &clock, ts::ctx(scenario));
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let strap_addr = strap::get_address(&strap);
            let (coll, debt) = bucket::get_bottle_info_with_interest_by_debtor(bucket, strap_addr, &clock);
            assert!(coll == 1005_000_000_000, 0);
            assert!(debt == 15_075_000_000, 0);
            let (coll, debt) = bucket::get_bottle_info_with_interest_by_debtor(bucket, new_debtor, &clock);
            assert!(coll == 30_000_000_000 - balance::value(&coll_out), 0);
            assert!(debt == 30_150_000_000 - borrow_amount, 0);
            balance::destroy_for_testing(coll_out);
            ts::return_to_sender(scenario, strap);
            ts::return_shared(protocol);
            ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }
}