#[test_only]
module bucket_protocol::test_strap_with_fee_rate {

    use std::vector;
    use std::option;
    use sui::sui::SUI;
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::balance;
    use sui::transfer;
    use sui::clock::Clock;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::strap::{Self, BottleStrap};
    use bucket_protocol::buck::{Self, BUCK, AdminCap, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::test_utils as tu;

    public fun strapper(): address { @0x2f1a66e1 }

    #[test]
    fun test_manage_bottle_with_strap(): Scenario {
        let (scenario_val, borrowers) = tu::setup_customly_with_interest(
            1_600,
            vector[
                1000_000_000_000,
                1500_000_000_000,
                2000_000_000_000,
            ],
            vector[
                1000_000_000_000,
                1000_000_000_000,
                1000_000_000_000,
            ],
        );
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, tu::dev());
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            
            buck::new_strap_with_fee_rate_to<SUI>(
                &admin_cap, 1_000, strapper(), ts::ctx(scenario),
            );

            ts::return_to_sender(scenario, admin_cap);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);

            let collateral_in = balance::create_for_testing<SUI>(1600_000_000_000);
            let buck_out_amount = 1000_000_000_000;
            let buck_out = buck::borrow_with_strap(
                &mut protocol,
                &oracle,
                &strap,
                &clock,
                collateral_in,
                buck_out_amount,
                option::none(),
                ts::ctx(scenario),
            );
            assert!(balance::value(&buck_out) == buck_out_amount, 0);
            balance::destroy_for_testing(buck_out);
            transfer::public_transfer(strap, strapper());

            ts::return_shared(protocol);
            ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);
            let strap_addr = strap::get_address(&strap);

            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (
                coll_amount,
                debt_amount,
            ) = bucket::get_bottle_info_with_interest_by_debtor(
                bucket, strap_addr, &clock,
            );
            assert!(coll_amount == 1600_000_000_000, 0);
            assert!(debt_amount == 1001_000_000_000, 0);
            let prev_debtor_opt = bucket::prev_debtor(bucket, strap_addr);
            let next_debtor_opt = bucket::next_debtor(bucket, strap_addr);

            let prev_debtor = vector::borrow(&borrowers, 1);
            assert!(option::contains(prev_debtor_opt, prev_debtor), 0);
            let next_debtor = vector::borrow(&borrowers, 2);
            assert!(option::contains(next_debtor_opt, next_debtor), 0);

            ts::return_to_sender(scenario, strap);
            ts::return_shared(protocol);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);
            let strap_address = strap::get_address(&strap);

            let top_up_amount = 500_000_000_000;
            let collateral_in = balance::create_for_testing<SUI>(top_up_amount);
            buck::top_up_coll(
                &mut protocol,
                collateral_in,
                strap_address,
                option::none(),
                &clock,
            );

            ts::return_to_sender(scenario, strap);
            ts::return_shared(protocol);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);
            let strap_addr = strap::get_address(&strap);

            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (
                coll_amount,
                debt_amount,
            ) = bucket::get_bottle_info_with_interest_by_debtor(
                bucket, strap_addr, &clock,
            );
            assert!(coll_amount == 2100_000_000_000, 0);
            assert!(debt_amount == 1001_000_000_000, 0);
            let prev_debtor_opt = bucket::prev_debtor(bucket, strap_addr);
            let next_debtor_opt = bucket::next_debtor(bucket, strap_addr);

            let prev_debtor = vector::borrow(&borrowers, 2);
            assert!(option::contains(prev_debtor_opt, prev_debtor), 0);
            assert!(option::is_none(next_debtor_opt), 0);

            ts::return_to_sender(scenario, strap);
            ts::return_shared(protocol);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);

            let withdraw_amount = 1200_000_000_000;
            let coll_out = buck::withdraw_with_strap(
                &mut protocol,
                &oracle,
                &strap,
                &clock,
                withdraw_amount,
                option::none(),
            );
            assert!(balance::value(&coll_out) == withdraw_amount, 0);
            balance::destroy_for_testing(coll_out);
            transfer::public_transfer(strap, strapper());

            ts::return_shared(protocol);
            ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);
            let strap_addr = strap::get_address(&strap);

            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (
                coll_amount,
                debt_amount,
            ) = bucket::get_bottle_info_with_interest_by_debtor(
                bucket, strap_addr, &clock,
            );
            assert!(coll_amount == 900_000_000_000, 0);
            assert!(debt_amount == 1001_000_000_000, 0);
            let prev_debtor_opt = bucket::prev_debtor(bucket, strap_addr);
            let next_debtor_opt = bucket::next_debtor(bucket, strap_addr);

            assert!(option::is_none(prev_debtor_opt), 0);
            let next_debtor = vector::borrow(&borrowers, 0);
            assert!(option::contains(next_debtor_opt, next_debtor), 0);

            ts::return_to_sender(scenario, strap);
            ts::return_shared(protocol);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);
            let strap_address = strap::get_address(&strap);

            let repay_amount = 300_000_000_000;
            let buck_in = balance::create_for_testing<BUCK>(repay_amount);
            let coll_out = buck::repay_with_strap(
                &mut protocol,
                &strap,
                buck_in,
                &clock,
            );
            buck::top_up_coll<SUI>(
                &mut protocol,
                coll_out,
                strap_address,
                option::none(),
                &clock,
            );

            ts::return_to_sender(scenario, strap);
            ts::return_shared(protocol);
            ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);
            let strap_addr = strap::get_address(&strap);

            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let (
                coll_amount,
                debt_amount,
            ) = bucket::get_bottle_info_with_interest_by_debtor(
                bucket, strap_addr, &clock,
            );
            assert!(coll_amount == 900_000_000_000, 0);
            assert!(debt_amount == 701_000_000_000, 0);
            let prev_debtor_opt = bucket::prev_debtor(bucket, strap_addr);
            let next_debtor_opt = bucket::next_debtor(bucket, strap_addr);

            let prev_debtor = vector::borrow(&borrowers, 0);
            assert!(option::contains(prev_debtor_opt, prev_debtor), 0);
            let next_debtor = vector::borrow(&borrowers, 1);
            assert!(option::contains(next_debtor_opt, next_debtor), 0);

            ts::return_to_sender(scenario, strap);
            ts::return_shared(protocol);
            ts::return_shared(clock);
        };

        scenario_val
    }

    #[test]
    fun test_destroy_empty_strap() {
        let scenario_val = test_manage_bottle_with_strap();
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);

            let repay_amount = 701_000_000_000;
            let buck_in = balance::create_for_testing<BUCK>(repay_amount);
            let coll_out = buck::repay_with_strap(
                &mut protocol,
                &strap,
                buck_in,
                &clock,
            );
            balance::destroy_for_testing(coll_out);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            bucket::destroy_empty_strap(bucket, strap);

            ts::return_shared(protocol);
            ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::ECannotDestroyNonEmptyStrap)]
    fun test_destroy_non_empty_strap() {
        let scenario_val = test_manage_bottle_with_strap();
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, strapper());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let strap = ts::take_from_sender<BottleStrap<SUI>>(scenario);

            let repay_amount = 691_000_000_000;
            let buck_in = balance::create_for_testing<BUCK>(repay_amount);
            let coll_out = buck::repay_with_strap(
                &mut protocol,
                &strap,
                buck_in,
                &clock,
            );
            balance::destroy_for_testing(coll_out);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            bucket::destroy_empty_strap(bucket, strap);

            ts::return_shared(protocol);
            ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }
}