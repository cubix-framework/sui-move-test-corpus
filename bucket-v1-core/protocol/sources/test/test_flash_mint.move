#[test_only]
module bucket_protocol::test_flash_mint {

    use std::option::{Self, Option};
    use sui::balance;
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::test_utils::create_one_time_witness;
    use bucket_protocol::buck::{Self, BucketProtocol, BUCK, AdminCap, FlashMintConfig};

    public fun setup_flash_mint_config(
        admin: address,
        fee_rate: u64,
        max_amount: u64,
        config_recipient: Option<address>,
    ): Scenario {
        let scenario_val = ts::begin(admin);
        let scenario = &mut scenario_val;
        {
            buck::share_for_testing(
                create_one_time_witness<BUCK>(),
                admin,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, admin);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            if (option::is_some(&config_recipient)) {
                let recipient = option::destroy_some(config_recipient);
                buck::create_flash_mint_config_to(
                    &admin_cap,
                    fee_rate,
                    max_amount,
                    recipient,
                    ts::ctx(scenario),
                );
            } else {
                buck::share_flash_mint_config(
                    &admin_cap,
                    fee_rate,
                    max_amount,
                    ts::ctx(scenario),          
                );
            };

            ts::return_to_sender(scenario, admin_cap);
        };

        scenario_val
    }

    #[test]
    fun test_flash_mint_with_owned_config() {
        let admin = @0xde1;
        let fee_rate = 0;
        let max_amount = 1_000_000_000_000_000;
        let user = @0x123;
        let scenario_val = setup_flash_mint_config(
            admin,
            fee_rate,
            max_amount,
            option::some(user),
        );
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, user);
        {
            let config = ts::take_from_sender<FlashMintConfig>(scenario);
            let protocol = ts::take_shared<BucketProtocol>(scenario);

            let (buck_loan, receipt) = buck::flash_mint(
                &mut protocol,
                &mut config,
                max_amount,
            );
            buck::flash_burn(&mut protocol, &mut config, buck_loan, receipt);

            ts::return_to_sender(scenario, config);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_flash_mint_with_shared_config() {
        let admin = @0xde1;
        let user = @0x123;
        let fee_rate = 10_000;
        let max_amount = 1_000_000_000_000;
        let scenario_val = setup_flash_mint_config(
            admin,
            fee_rate,
            max_amount,
            option::none(),
        );
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, user);
        {
            let config = ts::take_shared<FlashMintConfig>(scenario);
            let protocol = ts::take_shared<BucketProtocol>(scenario);

            let (buck_loan, receipt) = buck::flash_mint(
                &mut protocol,
                &mut config,
                max_amount/2,
            );
            let profit = balance::create_for_testing<BUCK>(max_amount/2/100);
            balance::join(&mut buck_loan, profit);
            buck::flash_burn(&mut protocol, &mut config, buck_loan, receipt);

            ts::return_shared(config);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);   
    }

    #[test]
    #[expected_failure(abort_code = buck::EInvalidFlashMintAmount)]
    fun test_invalid_flash_mint_amount() {
        let admin = @0xde1;
        let user = @0x123;
        let fee_rate = 10_000;
        let max_amount = 1_000_000_000_000;
        let scenario_val = setup_flash_mint_config(
            admin,
            fee_rate,
            max_amount,
            option::none(),
        );
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, admin);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let config = ts::take_shared<FlashMintConfig>(scenario);
            buck::update_flash_mint_config(
                &admin_cap,
                &mut config,
                fee_rate,
                max_amount - 1,
            );

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(config);
        };

        ts::next_tx(scenario, user);
        {
            let config = ts::take_shared<FlashMintConfig>(scenario);
            let protocol = ts::take_shared<BucketProtocol>(scenario);

            let (buck_loan, receipt) = buck::flash_mint(
                &mut protocol,
                &mut config,
                max_amount * 1/4,
            );
            let (buck_loan_2, receipt_2) = buck::flash_mint(
                &mut protocol,
                &mut config,
                max_amount * 3/4,
            );

            buck::flash_burn(&mut protocol, &mut config, buck_loan, receipt);
            buck::flash_burn(&mut protocol, &mut config, buck_loan_2, receipt_2);

            ts::return_shared(config);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::EFlashBurnNotEnought)]
    fun test_flash_burn_not_enough() {
        let admin = @0xde1;
        let user = @0x123;
        let fee_rate = 10_000;
        let max_amount = 1_000_000_000_000;
        let scenario_val = setup_flash_mint_config(
            admin,
            fee_rate,
            max_amount,
            option::none(),
        );
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, admin);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let config = ts::take_shared<FlashMintConfig>(scenario);
            buck::update_flash_mint_config(
                &admin_cap,
                &mut config,
                fee_rate + 1,
                max_amount,
            );

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(config);
        };

        ts::next_tx(scenario, user);
        {
            let config = ts::take_shared<FlashMintConfig>(scenario);
            let protocol = ts::take_shared<BucketProtocol>(scenario);

            let (buck_loan, receipt) = buck::flash_mint(
                &mut protocol,
                &mut config,
                max_amount,
            );
            let profit = balance::create_for_testing<BUCK>(max_amount/100);
            balance::join(&mut buck_loan, profit);
            buck::flash_burn(&mut protocol, &mut config, buck_loan, receipt);

            ts::return_shared(config);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = buck::EFlashMintConfigIdNotMatched)]
    fun test_invalid_flash_mint_config_id() {
        let admin = @0xde1;
        let user = @0x123;
        let fee_rate = 10_000;
        let max_amount = 1_000_000_000_000;
        let scenario_val = setup_flash_mint_config(
            admin,
            0,
            max_amount,
            option::some(user),
        );
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, admin);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            buck::share_flash_mint_config(&admin_cap, fee_rate, max_amount, ts::ctx(scenario));
            ts::return_to_sender(scenario, admin_cap);
        };

        ts::next_tx(scenario, user);
        {
            let shared_config = ts::take_shared<FlashMintConfig>(scenario);
            let owned_config = ts::take_from_sender<FlashMintConfig>(scenario);
            let protocol = ts::take_shared<BucketProtocol>(scenario);

            let (buck_loan, receipt) = buck::flash_mint(
                &mut protocol,
                &mut owned_config,
                max_amount,
            );
            let profit = balance::create_for_testing<BUCK>(max_amount/100);
            balance::join(&mut buck_loan, profit);
            buck::flash_burn(&mut protocol, &mut shared_config, buck_loan, receipt);

            ts::return_to_sender(scenario, owned_config);
            ts::return_shared(shared_config);
            ts::return_shared(protocol);
        };

        ts::end(scenario_val);
    }
}
