#[test_only]
module bucket_protocol::test_flash_loan {
    use sui::sui::SUI;
    use sui::balance;
    use sui::transfer;
    use sui::clock::Clock;
    use sui::test_scenario;
    use bucket_framework::math::mul_factor;
    use bucket_oracle::bucket_oracle::BucketOracle;
    use bucket_protocol::constants;
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
    use bucket_protocol::bucket;
    use bucket_protocol::tank;
    use bucket_protocol::well;
    use bucket_protocol::test_utils::{setup_randomly, setup_empty};

    #[test]
    fun test_flash_loan_sui() {
        let oracle_price = 1100;
        let borrower_count: u8 = 32;
        let (scenario_val, _) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let user = @0x1ac;
        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let flash_loan_amount = bucket::get_collateral_vault_balance(bucket);
            let (sui_loan, receipt) = buck::flash_borrow<SUI>(&mut protocol, flash_loan_amount);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(balance::value(&sui_loan) == flash_loan_amount, 0);
            let (loan_amount, required_fee_amount) = bucket::get_receipt_info(&receipt);
            assert!(balance::value(&sui_loan) == loan_amount, 0);
            let fee_amount = mul_factor(flash_loan_amount, constants::flash_loan_fee(), constants::fee_precision());
            assert!(required_fee_amount == fee_amount, 0);
            assert!(bucket::get_total_flash_loan_amount(bucket) == flash_loan_amount, 0);
            assert!(bucket::get_collateral_vault_balance(bucket) == 0, 0);
            let fee = balance::create_for_testing<SUI>(fee_amount);
            balance::join(&mut sui_loan, fee);
            buck::flash_repay(&mut protocol, sui_loan, receipt);
            let well = buck::borrow_well<SUI>(&protocol);
            assert!(well::get_well_reserve_balance(well) == fee_amount, 0);
            test_scenario::return_shared(protocol);
        };

        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let flash_loan_amount: u64 = 1999;
            let (sui_loan, receipt) = buck::flash_borrow<SUI>(&mut protocol, flash_loan_amount);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            assert!(balance::value(&sui_loan) == flash_loan_amount, 0);
            let (loan_amount, required_fee_amount) = bucket::get_receipt_info(&receipt);
            assert!(balance::value(&sui_loan) == loan_amount, 0);
            let fee_amount = 1;
            assert!(required_fee_amount == fee_amount, 0);
            assert!(bucket::get_total_flash_loan_amount(bucket) == flash_loan_amount, 0);
            let fee = balance::create_for_testing<SUI>(fee_amount);
            balance::join(&mut sui_loan, fee);
            buck::flash_repay(&mut protocol, sui_loan, receipt);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::EFlashFeeNotEnough)]
    fun test_fee_not_enough() {
        let oracle_price = 1200;
        let borrower_count: u8 = 25;
        let (scenario_val, _) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let user = @0x2ac;
        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bucket = buck::borrow_bucket<SUI>(&protocol);
            let flash_loan_amount = bucket::get_collateral_vault_balance(bucket);
            let (sui_loan, receipt) = buck::flash_borrow<SUI>(&mut protocol, flash_loan_amount);
            assert!(balance::value(&sui_loan) == flash_loan_amount, 0);
            let fee_amount = mul_factor(flash_loan_amount, constants::flash_loan_fee(), constants::fee_precision()) - 1;
            let fee = balance::create_for_testing<SUI>(fee_amount);
            balance::join(&mut sui_loan, fee);
            buck::flash_repay(&mut protocol, sui_loan, receipt);
            let well = buck::borrow_well<SUI>(&protocol);
            assert!(well::get_well_reserve_balance(well) == fee_amount, 0);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_flash_loan_buck() {
        let oracle_price = 900;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        let contributor = @0xa11ce;
        let tank_balance: u64 = 0xa11ce000;
        test_scenario::next_tx(scenario, contributor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_deposit_input = balance::create_for_testing<BUCK>(tank_balance);
            let token = tank::deposit(tank, buck_deposit_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, contributor);
            test_scenario::return_shared(protocol);
        };

        let user = @0x3ac;
        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank<SUI>(&protocol);
            let flash_loan_amount = tank::get_reserve_balance(tank);
            assert!(flash_loan_amount == tank_balance, 0);
            let (buck_loan, receipt) = buck::flash_borrow_buck<SUI>(&mut protocol, flash_loan_amount);
            let tank = buck::borrow_tank<SUI>(&protocol);
            let (loan_amount, required_fee_amount) = tank::get_receipt_info(&receipt);
            assert!(balance::value(&buck_loan) == flash_loan_amount, 0);
            assert!(balance::value(&buck_loan) == loan_amount, 0);
            assert!(tank::get_total_flash_loan_amount(tank) == flash_loan_amount, 0);
            assert!(tank::get_reserve_balance(tank) == 0, 0);
            let fee_amount = mul_factor(flash_loan_amount, constants::flash_loan_fee(), constants::fee_precision());
            assert!(required_fee_amount == fee_amount, 0);
            let fee = balance::create_for_testing<BUCK>(fee_amount);
            balance::join(&mut buck_loan, fee);
            buck::flash_repay_buck(&mut protocol, buck_loan, receipt);
            let well = buck::borrow_well<BUCK>(&protocol);
            assert!(well::get_well_reserve_balance(well) == fee_amount, 0);
            test_scenario::return_shared(protocol);
        };

        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let flash_loan_amount = 1995;
            let (buck_loan, receipt) = buck::flash_borrow_buck<SUI>(&mut protocol, flash_loan_amount);
            let (loan_amount, required_fee_amount) = tank::get_receipt_info(&receipt);
            let tank = buck::borrow_tank<SUI>(&protocol);
            assert!(balance::value(&buck_loan) == flash_loan_amount, 0);
            assert!(balance::value(&buck_loan) == loan_amount, 0);
            assert!(tank::get_total_flash_loan_amount(tank) == flash_loan_amount, 0);
            let fee_amount = 1;
            assert!(required_fee_amount == fee_amount, 0);
            let fee = balance::create_for_testing<BUCK>(fee_amount);
            balance::join(&mut buck_loan, fee);
            buck::flash_repay_buck(&mut protocol, buck_loan, receipt);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = tank::EFlashFeeNotEnough)]
    fun test_buck_fee_not_enough() {
        let oracle_price = 900;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        let contributor = @0xb0b;
        let tank_balance: u64 = 0xb0b000123;
        test_scenario::next_tx(scenario, contributor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_deposit_input = balance::create_for_testing<BUCK>(tank_balance);
            let token = tank::deposit(tank, buck_deposit_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, contributor);
            test_scenario::return_shared(protocol);
        };

        let user = @0x4ac;
        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank<SUI>(&protocol);
            let flash_loan_amount = tank::get_reserve_balance(tank);
            assert!(flash_loan_amount == tank_balance, 0);
            let (buck_loan, receipt) = buck::flash_borrow_buck<SUI>(&mut protocol, flash_loan_amount);
            assert!(balance::value(&buck_loan) == flash_loan_amount, 0);
            let fee_amount = mul_factor(flash_loan_amount, constants::flash_loan_fee(), constants::fee_precision()) - 1;
            let fee = balance::create_for_testing<BUCK>(fee_amount);
            balance::join(&mut buck_loan, fee);
            buck::flash_repay_buck(&mut protocol, buck_loan, receipt);
            let well = buck::borrow_well<BUCK>(&protocol);
            assert!(well::get_well_reserve_balance(well) == fee_amount, 0);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bucket::EBucketLocked)]
    fun test_bucket_locked() {
        let oracle_price = 1145;
        let borrower_count: u8 = 45;
        let (scenario_val, _) = setup_randomly(oracle_price, borrower_count);
        let scenario = &mut scenario_val;

        let user = @0x5ac;
        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let oracle = test_scenario::take_shared<BucketOracle>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let flash_loan_amount = 1;
            let (sui_loan, receipt) = buck::flash_borrow<SUI>(&mut protocol, flash_loan_amount);
            let sui_input = balance::create_for_testing<SUI>(1000_000_000_000_000);
            let buck_output_amount = 500_000_000_00;
            let buck_output = buck::borrow(&mut protocol, &oracle, &clock, sui_input, buck_output_amount, std::option::none(), test_scenario::ctx(scenario));
            balance::destroy_for_testing(buck_output);
            buck::flash_repay(&mut protocol, sui_loan, receipt);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(oracle);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = tank::ETankLocked)]
    fun test_tank_locked() {
        let oracle_price = 900;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        let contributor = @0x77777;
        let tank_balance: u64 = 0x77777;
        test_scenario::next_tx(scenario, contributor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_deposit_input = balance::create_for_testing<BUCK>(tank_balance);
            let token = tank::deposit(tank, buck_deposit_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, contributor);
            test_scenario::return_shared(protocol);
        };

        let user = @0x6ac;
        test_scenario::next_tx(scenario, user);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let flash_loan_amount = 69;
            let (buck_loan, receipt) = buck::flash_borrow_buck<SUI>(&mut protocol, flash_loan_amount);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let buck_deposit_input = balance::create_for_testing<BUCK>(69);
            let token = tank::deposit(tank, buck_deposit_input, test_scenario::ctx(scenario));
            transfer::public_transfer(token, contributor);
            buck::flash_repay_buck(&mut protocol, buck_loan, receipt);
            test_scenario::return_shared(protocol);
        };

        test_scenario::end(scenario_val);
    }
}