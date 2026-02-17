#[test_only]
module bucket_protocol::test_pipe {
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::clock::Clock;
    use sui::tx_context::TxContext;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::buck::{Self, BUCK, AdminCap, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::pipe;
    use bucket_protocol::test_utils::{setup_randomly, setup_empty, dev};

    struct Rule has drop {}

    struct Rule2 has drop {}

    struct Pond<phantom T> has key {
        id: UID,
        balance: Balance<T>,
    }

    public fun create<T>(ctx: &mut TxContext) {
        let pond = Pond<T> { id: object::new(ctx), balance: balance::zero() };
        transfer::share_object(pond);
    }

    public fun protocol_to_pond<T>(
        protocol: &mut BucketProtocol,
        pond: &mut Pond<T>,
        amount: u64,
        is_default: bool,
    ) {
        if (is_default) {
            let carrier = buck::output<T, Rule>(protocol, amount);
            let content = pipe::destroy_output_carrier(Rule {}, carrier);
            balance::join(&mut pond.balance, content);
        } else {
            let carrier = buck::output<T, Rule2>(protocol, amount);
            let content = pipe::destroy_output_carrier(Rule2 {}, carrier);
            balance::join(&mut pond.balance, content);
        };
    }

    public fun pond_to_protocol<T>(
        protocol: &mut BucketProtocol,
        pond: &mut Pond<T>,
        amount: u64,
        is_default: bool,
    ) {
        if (is_default) {
            let content = balance::split(&mut pond.balance, amount);
            let carrier = pipe::input(Rule {}, content);
            buck::input(protocol, carrier);
        } else {
            let content = balance::split(&mut pond.balance, amount);
            let carrier = pipe::input(Rule2 {}, content);
            buck::input(protocol, carrier);
        };
    }

    public fun protocol_to_pond_for_buck(
        protocol: &mut BucketProtocol,
        pond: &mut Pond<BUCK>,
        amount: u64,
        is_default: bool,
    ) {
        if (is_default) {
            let carrier = buck::output_buck<Rule>(protocol, amount);
            let content = pipe::destroy_output_carrier(Rule {}, carrier);
            balance::join(&mut pond.balance, content);
        } else {
            let carrier = buck::output_buck<Rule2>(protocol, amount);
            let content = pipe::destroy_output_carrier(Rule2 {}, carrier);
            balance::join(&mut pond.balance, content);
        };
    }

    public fun pond_to_protocol_for_buck(
        protocol: &mut BucketProtocol,
        pond: &mut Pond<BUCK>,
        amount: u64,
        is_default: bool,
    ) {
        if (is_default) {
            let content = balance::split(&mut pond.balance, amount);
            let carrier = pipe::input(Rule {}, content);
            buck::input_buck(protocol, carrier);
        } else {
            let content = balance::split(&mut pond.balance, amount);
            let carrier = pipe::input(Rule2 {}, content);
            buck::input_buck(protocol, carrier);
        };
    }

    public fun pond_balance<T>(pond: &Pond<T>): u64 {
        balance::value(&pond.balance)
    }

    #[test]
    fun test_pipe_output(): Scenario {
        let oracle_price: u64 = 1050;
        let borrower_count: u8 = 50;
        let (scenario_val, _borrowers) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;
 
        ts::next_tx(scenario, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            buck::create_pipe<SUI, Rule>(&admin_cap, &mut protocol, ts::ctx(scenario));
            buck::create_pipe<SUI, Rule2>(&admin_cap, &mut protocol, ts::ctx(scenario));
            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(protocol);
            create<SUI>(ts::ctx(scenario));
        };

        ts::next_tx(scenario, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let oracle = ts::take_shared<BucketOracle>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let collateral_balance_0 = bucket::get_collateral_vault_balance(bucket);
            let output_volume_0 = bucket::get_collateral_output_volume(bucket);
            let collateral_value_0 = bucket::get_total_collateral_balance(bucket);
            let tcr = bucket::get_bucket_tcr(bucket, &oracle, &clock);
            assert!(collateral_balance_0 + output_volume_0 == collateral_value_0, 0);
            assert!(!bucket::is_in_recovery_mode(bucket, &oracle, &clock), 0);
            let pipe = buck::borrow_pipe<SUI, Rule>(&protocol);
            assert!(pipe::output_volume(pipe) == 0, 0);
            let pond = ts::take_shared<Pond<SUI>>(scenario);

            let out_amount = collateral_balance_0 / 2;
            protocol_to_pond(&mut protocol, &mut pond, out_amount, true);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let collateral_balance_1 = bucket::get_collateral_vault_balance(bucket);
            let output_volume_1 = bucket::get_collateral_output_volume(bucket);
            let collateral_value_1 = bucket::get_total_collateral_balance(bucket);
            assert!(collateral_balance_1 + output_volume_1 == collateral_value_1, 0);
            assert!(collateral_balance_0 - out_amount == collateral_balance_1, 0);
            assert!(output_volume_1 == out_amount, 0);
            assert!(collateral_balance_0 == collateral_value_1, 0);
            assert!(tcr == bucket::get_bucket_tcr(bucket, &oracle, &clock), 0);
            assert!(!bucket::is_in_recovery_mode(bucket, &oracle, &clock), 0);
            assert!(pond_balance(&pond) == output_volume_1, 0);
            let pipe = buck::borrow_pipe<SUI, Rule>(&protocol);
            assert!(pipe::output_volume(pipe) == output_volume_1, 0);

            let in_amount = collateral_balance_0 / 3;
            pond_to_protocol(&mut protocol, &mut pond, in_amount, true);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let collateral_balance_2 = bucket::get_collateral_vault_balance(bucket);
            let output_volume_2 = bucket::get_collateral_output_volume(bucket);
            let collateral_value_2 = bucket::get_total_collateral_balance(bucket);
            assert!(collateral_balance_2 + output_volume_2 == collateral_value_2, 0);
            assert!(collateral_balance_0 - out_amount + in_amount == collateral_balance_2, 0);
            assert!(output_volume_2 == out_amount - in_amount, 0);
            assert!(collateral_balance_0 == collateral_value_2, 0);
            assert!(tcr == bucket::get_bucket_tcr(bucket, &oracle, &clock), 0);
            assert!(!bucket::is_in_recovery_mode(bucket, &oracle, &clock), 0);
            assert!(pond_balance(&pond) == output_volume_2, 0);
            let pipe = buck::borrow_pipe<SUI, Rule>(&protocol);
            assert!(pipe::output_volume(pipe) == output_volume_2, 0);

            let rest_amount = collateral_balance_2;
            protocol_to_pond(&mut protocol, &mut pond, rest_amount, false);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let collateral_balance_3 = bucket::get_collateral_vault_balance(bucket);
            let output_volume_3 = bucket::get_collateral_output_volume(bucket);
            let collateral_value_3 = bucket::get_total_collateral_balance(bucket);
            assert!(collateral_balance_3 + output_volume_3 == collateral_value_3, 0);
            assert!(collateral_balance_0 == output_volume_3, 0);
            assert!(collateral_balance_3 == 0, 0);
            assert!(collateral_balance_0 == collateral_value_3, 0);
            assert!(tcr == bucket::get_bucket_tcr(bucket, &oracle, &clock), 0);
            assert!(!bucket::is_in_recovery_mode(bucket, &oracle, &clock), 0);
            assert!(pond_balance(&pond) == output_volume_3, 0);
            let pipe = buck::borrow_pipe<SUI, Rule>(&protocol);
            let pipe_volume = pipe::output_volume(pipe);
            assert!(pipe_volume == output_volume_2, 0);
            let pipe = buck::borrow_pipe<SUI, Rule2>(&protocol);
            let pipe_2_volume = pipe::output_volume(pipe);
            assert!(pipe_2_volume == rest_amount, 0);
            assert!(pipe_volume + pipe_2_volume == output_volume_3, 0);

            ts::return_shared(protocol);
            ts::return_shared(pond);
            ts::return_shared(oracle);
            ts::return_shared(clock);
        };

        scenario_val
    }

    #[test, expected_failure(abort_code = pipe::EDestroyNonEmptyPipe)]
    fun test_destroy_pipe_failure() {
        let scenario = test_pipe_output();
        let s = &mut scenario;

        ts::next_tx(s, dev());
        {
            let cap = ts::take_from_sender<AdminCap>(s);
            let protocol = ts::take_shared<BucketProtocol>(s);
            buck::destroy_pipe<SUI, Rule>(&cap, &mut protocol);
            ts::return_to_sender(s, cap);
            ts::return_shared(protocol);
        };

        ts::end(scenario);
    }

    #[test, expected_failure(abort_code = buck::ECannotUseNormalPipeForBuck)]
    fun test_output_buck_through_normal_pipe(): Scenario {
        let scenario_val = setup_empty(1000);
        let s = &mut scenario_val;
 
        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let admin_cap = ts::take_from_sender<AdminCap>(s);
            buck::create_pipe<BUCK, Rule>(&admin_cap, &mut protocol, ts::ctx(s));
            ts::return_to_sender(s, admin_cap);
            ts::return_shared(protocol);
            create<BUCK>(ts::ctx(s));
        };

        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let pond = ts::take_shared<Pond<BUCK>>(s);

            let out_amount = 1_000_000_000_000;
            protocol_to_pond(&mut protocol, &mut pond, out_amount, true);
            ts::return_shared(protocol);
            ts::return_shared(pond);
        };

        scenario_val
    }

    #[test]
        fun test_output_buck(): Scenario {
        let scenario_val = setup_empty(1000);
        let s = &mut scenario_val;
 
        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let admin_cap = ts::take_from_sender<AdminCap>(s);
            buck::create_pipe<BUCK, Rule>(&admin_cap, &mut protocol, ts::ctx(s));
            ts::return_to_sender(s, admin_cap);
            ts::return_shared(protocol);
            create<BUCK>(ts::ctx(s));
        };

        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let pond = ts::take_shared<Pond<BUCK>>(s);

            let out_amount = 1_000_000_000_000;
            protocol_to_pond_for_buck(&mut protocol, &mut pond, out_amount, true);
            assert!(pond_balance(&pond) == out_amount, 0);
            let pipe = buck::borrow_pipe<BUCK, Rule>(&protocol);
            assert!(pipe::output_volume(pipe) == out_amount, 0);

            let in_amount = 690_000_000_000;
            pond_to_protocol_for_buck(&mut protocol, &mut pond, in_amount, true);
            assert!(pond_balance(&pond) == out_amount - in_amount, 0);
            let pipe = buck::borrow_pipe<BUCK, Rule>(&protocol);
            assert!(pipe::output_volume(pipe) == out_amount - in_amount, 0);

            let rest_amount = out_amount - in_amount;
            pond_to_protocol_for_buck(&mut protocol, &mut pond, rest_amount, true);
            assert!(pond_balance(&pond) == 0, 0);
            let pipe = buck::borrow_pipe<BUCK, Rule>(&protocol);
            assert!(pipe::output_volume(pipe) == 0, 0);

            ts::return_shared(protocol);
            ts::return_shared(pond);
        };

        scenario_val
    }

    #[test]
    fun test_destroy_buck_pipe() {
        let scenario = test_output_buck();
        let s = &mut scenario;

        ts::next_tx(s, dev());
        {
            let cap = ts::take_from_sender<AdminCap>(s);
            let protocol = ts::take_shared<BucketProtocol>(s);
            buck::destroy_pipe<BUCK, Rule>(&cap, &mut protocol);
            ts::return_to_sender(s, cap);
            ts::return_shared(protocol);
        };

        ts::end(scenario);
    }

    #[test, expected_failure(abort_code = buck::ENotSupportedType)]
    fun test_invalid_rule_for_buck() {
        let scenario_val = setup_empty(1000);
        let s = &mut scenario_val;
 
        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let admin_cap = ts::take_from_sender<AdminCap>(s);
            buck::create_pipe<BUCK, Rule2>(&admin_cap, &mut protocol, ts::ctx(s));
            ts::return_to_sender(s, admin_cap);
            ts::return_shared(protocol);
            create<BUCK>(ts::ctx(s));
        };

        ts::next_tx(s, dev());
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let pond = ts::take_shared<Pond<BUCK>>(s);

            let out_amount = 1_000_000_000_000;
            protocol_to_pond_for_buck(&mut protocol, &mut pond, out_amount, true);

            ts::return_shared(protocol);
            ts::return_shared(pond);
        };

        ts::end(scenario_val);   
    }
}
