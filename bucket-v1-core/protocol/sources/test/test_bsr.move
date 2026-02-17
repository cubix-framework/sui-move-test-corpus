#[test_only]
module bucket_protocol::test_bsr {

    use sui::transfer;    
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self};
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::clock::{Self, Clock};
    use flask::sbuck::{Self, SBUCK, Flask};
    use flask::sbuck_tests_v2::{within_rounding};
    use bucket_protocol::test_utils as tu;
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol, BUCKET_PROTOCOL, AdminCap};

    public fun start_bsr_time(): u64 { 1726074044155 }

    public fun start_buck_supply(): u64 { 6232065462391947 }

    public fun setup(interest_rate_bps: u64): Scenario {
        let deployer = tu::dev();
        let scenario = tu::setup_empty(0);
        let s = &mut scenario;

        ts::next_tx(s, deployer);
        {
            sbuck::init_for_testing(ts::ctx(s));
        };
        
        ts::next_tx(s, deployer);
        {
            let sbuck_cap = ts::take_from_sender<TreasuryCap<SBUCK>>(s);
            sbuck::initialize<BUCK>(sbuck_cap, ts::ctx(s));
        };

        ts::next_tx(s, deployer);
        {
            let flask = ts::take_shared<Flask<BUCK>>(s);
            sbuck::patch_whitelist_for_testing<BUCK, BUCKET_PROTOCOL>(&mut flask);
            ts::return_shared(flask);
        };

        ts::next_tx(s, deployer);
        {
            let cap = ts::take_from_sender<AdminCap>(s);
            let protocol = ts::take_shared<BucketProtocol>(s);
            let flask = ts::take_shared<Flask<BUCK>>(s);
            let clock = ts::take_shared<Clock>(s);
            clock::set_for_testing(&mut clock, start_bsr_time());

            buck::set_sbuck_rate(
                &cap,
                &mut protocol,
                &mut flask,
                &clock, 
                interest_rate_bps,
                ts::ctx(s),
            );
            
            let sbuck_out = buck::buck_to_sbuck(
                &mut protocol,
                &mut flask,
                &clock,
                balance::create_for_testing<BUCK>(start_buck_supply()),
            );
            assert!(balance::value(&sbuck_out) == start_buck_supply(), 0);
            balance::destroy_for_testing(sbuck_out);


            ts::return_to_sender(s, cap);
            ts::return_shared(protocol);
            ts::return_shared(flask);
            ts::return_shared(clock);
        };

        scenario
    }

    public fun deposit(
        s: &mut Scenario,
        user: address,
        amount: u64,
    ) {
        ts::next_tx(s, user);
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let flask = ts::take_shared<Flask<BUCK>>(s);
            let clock = ts::take_shared<Clock>(s);
            let buck_in = balance::create_for_testing<BUCK>(amount);
            let sbuck_out = buck::buck_to_sbuck(
                &mut protocol, &mut flask, &clock, buck_in,
            );
            let sbuck_out = coin::from_balance(sbuck_out, ts::ctx(s));
            transfer::public_transfer(sbuck_out, user);
            ts::return_shared(flask);
            ts::return_shared(protocol);
            ts::return_shared(clock);
        };
    }

    public fun withdraw(
        s: &mut Scenario,
        user: address,
    ) {
        ts::next_tx(s, user);
        {
            let protocol = ts::take_shared<BucketProtocol>(s);
            let flask = ts::take_shared<Flask<BUCK>>(s);
            let clock = ts::take_shared<Clock>(s);
            let sbuck_in = ts::take_from_sender<Coin<SBUCK>>(s);
            let sbuck_in = coin::into_balance(sbuck_in);
            let buck_out = buck::sbuck_to_buck(
                &mut protocol, &mut flask, &clock, sbuck_in,
            );
            let buck_out = coin::from_balance(buck_out, ts::ctx(s));
            transfer::public_transfer(buck_out, user);
            ts::return_shared(flask);
            ts::return_shared(protocol);
            ts::return_shared(clock);
        };
    }

    public fun time_pass_by(s: &mut Scenario, tick: u64) {
        ts::next_tx(s, tu::dev());
        {
            let clock = ts::take_shared<Clock>(s);
            clock::increment_for_testing(&mut clock, tick);
            ts::return_shared(clock);
        };
    }

    public fun buck_value_eq(
        s: &mut Scenario,
        user: address,
        expected_value: u64,
    ): bool {
        ts::next_tx(s, user);
        {
            let buck_coin = ts::take_from_sender<Coin<BUCK>>(s);
            // std::debug::print(&buck_coin.value());
            let buck_value = coin::value(&buck_coin);
            coin::burn_for_testing(buck_coin);
            within_rounding(buck_value, expected_value)
        }
    }

    #[test]
    fun test_withdraw_after_one_year() {
        let interest_rate_bps = 400; // 400 bps = 4%
        let scenario = setup(interest_rate_bps);
        let s = &mut scenario;
        let user = @0xabc;

        deposit(s, user, 100_000_000_000);
        time_pass_by(s, 365 * 86400_000); // one year 
        withdraw(s, user);

        let expected_value = 104_000_000_000;
        assert!(buck_value_eq(s, user, expected_value), 0);

        ts::end(scenario);
    }

    #[test]
    fun test_user_deposit_after_half_year() {
        let interest_rate_bps = 400; // 400 bps = 4%
        let scenario = setup(interest_rate_bps);
        let s = &mut scenario;
        let user_1 = @0xabc1;
        let user_2 = @0xabc2;

        deposit(s, user_1, 100_000_000_000);
        time_pass_by(s, 365 * 86400_000 / 2); // half year
        deposit(s, user_2, 200_000_000_000);
        time_pass_by(s, 365 * 86400_000 / 2); // half year
        
        withdraw(s, user_1);
        assert!(buck_value_eq(s, user_1, 104_040_000_000), 0);
        withdraw(s, user_2);
        assert!(buck_value_eq(s, user_2, 204_000_000_000), 0);

        ts::end(scenario);
    }

    #[test]
    fun test_update_interest_rate() {
        let interest_rate_bps = 400; // 400 bps = 4%
        let scenario = setup(0);
        let s = &mut scenario;
        let user_1 = @0xabc1;
        let user_2 = @0xabc2;
        
        deposit(s, user_1, 500_000_000_000);
        time_pass_by(s, 3 * 86400_000);
        deposit(s, user_2, 1_000_000_000_000);
        time_pass_by(s, 4 * 86400_000);

        withdraw(s, user_1);
        assert!(buck_value_eq(s, user_1, 500_000_000_000), 0);
        withdraw(s, user_2);
        assert!(buck_value_eq(s, user_2, 1_000_000_000_000), 0);

        deposit(s, user_1, 500_000_000_000);
        time_pass_by(s, 3 * 86400_000);
        deposit(s, user_2, 1_000_000_000_000);
        time_pass_by(s, 4 * 86400_000);

        // update interest rate to 4%
        ts::next_tx(s, tu::dev());
        {
            let cap = ts::take_from_sender<AdminCap>(s);
            let protocol = ts::take_shared<BucketProtocol>(s);
            let flask = ts::take_shared<Flask<BUCK>>(s);
            let clock = ts::take_shared<Clock>(s);

            buck::set_sbuck_rate(
                &cap,
                &mut protocol,
                &mut flask,
                &clock, 
                interest_rate_bps,
                ts::ctx(s),
            );

            ts::return_to_sender(s, cap);
            ts::return_shared(protocol);
            ts::return_shared(flask);
            ts::return_shared(clock);
        };

        time_pass_by(s, 365 * 86400_000);
        withdraw(s, user_1);
        assert!(buck_value_eq(s, user_1, 520_000_000_000), 0);
        time_pass_by(s, 365 * 86400_000 / 2);
        withdraw(s, user_2);
        assert!(buck_value_eq(s, user_2, 1_060_800_000_000), 0);

        deposit(s, user_1, 1_000_000_000_000_000);

        time_pass_by(s, 365 * 86400_000);

        // update interest rate to 8%
        ts::next_tx(s, tu::dev());
        {
            let cap = ts::take_from_sender<AdminCap>(s);
            let protocol = ts::take_shared<BucketProtocol>(s);
            let flask = ts::take_shared<Flask<BUCK>>(s);
            let clock = ts::take_shared<Clock>(s);

            buck::set_sbuck_rate(
                &cap,
                &mut protocol,
                &mut flask,
                &clock, 
                interest_rate_bps * 2,
                ts::ctx(s),
            );

            ts::return_to_sender(s, cap);
            ts::return_shared(protocol);
            ts::return_shared(flask);
            ts::return_shared(clock);
        };   

        time_pass_by(s, 365 * 86400_000);
        withdraw(s, user_1);
        assert!(buck_value_eq(s, user_1, 1_123_200_000_000_000), 0);

        ts::end(scenario);
    }
}