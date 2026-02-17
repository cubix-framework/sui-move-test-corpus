#[test_only]
module 0x111::stable {
    struct STABLE has drop {}
}

#[test_only]
module 0x222::stable_lp {
    struct STABLE_LP has drop {}
}

#[test_only]
module bucket_protocol::test_reservoir {

    use sui::balance;
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::test_utils::create_one_time_witness;
    use bucket_protocol::buck::{Self, BucketProtocol, BUCK, AdminCap, NoFeePermission};
    use bucket_protocol::well;
    use bucket_protocol::reservoir;
    use 0x111::stable::STABLE;

    struct Partner has drop {}

    public fun setup_reservior<T>(
        admin: address,
        conversion_rate: u64,
        charge_fee: u64,
        discharge_fee: u64,
    ): Scenario {
        let scenario_val = ts::begin(admin);
        let scenario = &mut scenario_val;
        {
            buck::share_for_testing(
                create_one_time_witness<BUCK>(),
                admin,
                ts::ctx(scenario),
            );
        };

        ts::next_tx(scenario, admin);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            buck::create_reservoir<T>(
                &admin_cap,
                &mut protocol,
                conversion_rate,
                charge_fee,
                discharge_fee,
                ts::ctx(scenario),
            );
            buck::create_no_fee_permission_to(
                &admin_cap,
                admin,
                ts::ctx(scenario),
            );
            buck::create_flash_mint_config_to(
                &admin_cap,
                500,
                1_000_000_000_000_000,
                admin,
                ts::ctx(scenario),
            );
            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(protocol);
        };

        scenario_val
    }

    #[test]
    fun test_charge_and_discharge() {
        let admin: address = @0xde1;
        let scenario_val = setup_reservior<STABLE>(
            admin,
            1_000_000_000,
            1_000,
            2_000,
        );
        let scenario = &mut scenario_val;

        let user = @0x123;
        let charge_amount = 1_000_000_000_000;
        ts::next_tx(scenario, user);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let stable_in = balance::create_for_testing<STABLE>(charge_amount);
            let buck_out = buck::charge_reservoir<STABLE>(&mut protocol, stable_in);
            assert!(balance::value(&buck_out) == charge_amount * 999/1000, 0);
            balance::destroy_for_testing(buck_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, user);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == charge_amount, 0);
            let well = buck::borrow_well<BUCK>(&protocol);
            assert!(well::get_well_reserve_balance(well) == charge_amount/1000, 0);
            let buck_in = balance::create_for_testing<BUCK>(charge_amount);
            let stable_out = buck::discharge_reservoir<STABLE>(&mut protocol, buck_in);
            assert!(balance::value(&stable_out) == charge_amount * 998/1000, 0);
            balance::destroy_for_testing(stable_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, admin);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == 0, 0);
            let well = buck::borrow_well<STABLE>(&protocol);
            assert!(well::get_well_reserve_balance(well) == charge_amount/500, 0);
            
            buck::update_reservoir_fee_rate<STABLE>(
                &admin_cap,
                &mut protocol,
                2_000,
                4_000,
            );
            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(protocol);
        };

        let user = @0x456;
        ts::next_tx(scenario, user);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let stable_in = balance::create_for_testing<STABLE>(charge_amount);
            let buck_out = buck::charge_reservoir<STABLE>(&mut protocol, stable_in);
            assert!(balance::value(&buck_out) == charge_amount * 998/1000, 0);
            balance::destroy_for_testing(buck_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, user);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == charge_amount, 0);
            let well = buck::borrow_well<BUCK>(&protocol);
            assert!(well::get_well_reserve_balance(well) == charge_amount * 3/1000, 0);
            let buck_in = balance::create_for_testing<BUCK>(charge_amount/2);
            let stable_out = buck::discharge_reservoir<STABLE>(&mut protocol, buck_in);
            assert!(balance::value(&stable_out) == charge_amount * 498/1000, 0);
            balance::destroy_for_testing(stable_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == charge_amount/2, 0);
            let well = buck::borrow_well<STABLE>(&protocol);
            assert!(well::get_well_reserve_balance(well) == charge_amount/250, 0);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_charge_and_discharge_without_fee() {
        let admin: address = @0xde1;
        let scenario_val = setup_reservior<STABLE>(
            admin,
            1_000_000_000_000,
            5_000,
            5_000,
        );
        let scenario = &mut scenario_val;

        let charge_amount = 5_000_000;
        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let permission = ts::take_from_sender<NoFeePermission>(scenario);
            let stable_in = balance::create_for_testing<STABLE>(charge_amount);
            let buck_out = buck::charge_reservoir_without_fee<STABLE>(
                &permission,
                &mut protocol,
                stable_in,
            );
            assert!(balance::value(&buck_out) == 5_000_000_000, 0);
            balance::destroy_for_testing(buck_out);
            ts::return_shared(protocol);
            ts::return_to_sender(scenario, permission);
        };

        let discharge_amount = 2_000_000_000;
        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == charge_amount, 0);
            let permission = ts::take_from_sender<NoFeePermission>(scenario);
            let buck_in = balance::create_for_testing<BUCK>(discharge_amount);
            let stable_out = buck::discharge_reservoir_without_fee<STABLE>(
                &permission,
                &mut protocol,
                buck_in,
            );
            assert!(balance::value(&stable_out) == 2_000_000, 0);
            balance::destroy_for_testing(stable_out);
            ts::return_shared(protocol);
            ts::return_to_sender(scenario, permission);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == 3_000_000, 0);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_charge_and_discharge_by_partner() {
        let admin: address = @0xde1;
        let scenario_val = setup_reservior<STABLE>(
            admin,
            1_000_000_000_000,
            5_000,
            5_000,
        );
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            buck::set_reservoir_partner<STABLE, Partner>(
                &admin_cap,
                &mut protocol,
                1_000,
                0,
            );

            ts::return_shared(protocol);
            ts::return_to_sender(scenario, admin_cap);
        };

        let charge_amount = 5_000_000;
        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let stable_in = balance::create_for_testing<STABLE>(charge_amount);
            let buck_out = buck::charge_reservoir_by_partner(
                &mut protocol,
                stable_in,
                Partner {},
            );
            assert!(balance::value(&buck_out) == 4_995_000_000, 0);
            balance::destroy_for_testing(buck_out);
            ts::return_shared(protocol);
        };

        let discharge_amount = 2_000_000_000;
        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == charge_amount, 0);
            let buck_in = balance::create_for_testing<BUCK>(discharge_amount);
            let stable_out = buck::discharge_reservoir_by_partner<STABLE, Partner>(
                &mut protocol,
                buck_in,
                Partner {},
            );
            assert!(balance::value(&stable_out) == 2_000_000, 0);
            balance::destroy_for_testing(stable_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == 3_000_000, 0);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            buck::set_reservoir_partner<STABLE, Partner>(
                &admin_cap,
                &mut protocol,
                0,
                1_000,
            );

            ts::return_shared(protocol);
            ts::return_to_sender(scenario, admin_cap);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let stable_in = balance::create_for_testing<STABLE>(charge_amount);
            let buck_out = buck::charge_reservoir_by_partner(
                &mut protocol,
                stable_in,
                Partner {},
            );
            assert!(balance::value(&buck_out) == 5_000_000_000, 0);
            balance::destroy_for_testing(buck_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == charge_amount + 3_000_000, 0);
            let buck_in = balance::create_for_testing<BUCK>(discharge_amount);
            let stable_out = buck::discharge_reservoir_by_partner<STABLE, Partner>(
                &mut protocol,
                buck_in,
                Partner {},
            );
            assert!(balance::value(&stable_out) == 1_998_000, 0);
            balance::destroy_for_testing(stable_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == 6_000_000, 0);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_charge_and_discharge_by_non_partner() {
        let admin: address = @0xde1;
        let scenario_val = setup_reservior<STABLE>(
            admin,
            1_000_000_000_000,
            5_000,
            5_000,
        );
        let scenario = &mut scenario_val;

        let charge_amount = 5_000_000;
        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let stable_in = balance::create_for_testing<STABLE>(charge_amount);
            let buck_out = buck::charge_reservoir_by_partner(
                &mut protocol,
                stable_in,
                Partner {},
            );
            assert!(balance::value(&buck_out) == 4_975_000_000, 0);
            balance::destroy_for_testing(buck_out);
            ts::return_shared(protocol);
        };

        let discharge_amount = 2_000_000_000;
        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == charge_amount, 0);
            let buck_in = balance::create_for_testing<BUCK>(discharge_amount);
            let stable_out = buck::discharge_reservoir_by_partner<STABLE, Partner>(
                &mut protocol,
                buck_in,
                Partner {},
            );
            assert!(balance::value(&stable_out) == 1_990_000, 0);
            balance::destroy_for_testing(stable_out);
            ts::return_shared(protocol);
        };

        ts::next_tx(scenario, admin);
        {
            let protocol = ts::take_shared<BucketProtocol>(scenario);
            let reservoir = buck::borrow_reservoir<STABLE>(&protocol);
            assert!(reservoir::pool_balance(reservoir) == 3_000_000, 0);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }
}
