// #[test_only]

// module bucket_protocol::test_redistribution {
//     use sui::test_scenario;
//     use std::vector;
//     use bucket_protocol::constants::{decimal_factor};
//     use bucket_protocol::test_utils::{
//         setup_customly, 
//         get_coin_amount_times_decimal, 
//         open_bottle_by_icr, 
//         set_coll_price, 
//         liquidate_normal_mode, 
//         check_bottle_info,
//         dev,
//     };

//     #[test]
//     fun test_distributes_correct_rewards_four_open_two_redistribution() {
//         let oracle_price: u64 = 1000;
//         let coll = get_coin_amount_times_decimal(
//             vector<u64>[2000, 1050], 
//             decimal_factor()
//         );
//         let debt = get_coin_amount_times_decimal(
//             vector<u64>[500, 500], 
//             decimal_factor()
//         );

//         let (scenario_val, borrowers) =
//             setup_customly(oracle_price, coll, debt);
//         let scenario = &mut scenario_val;
        
//         // coll price drop
//         set_coll_price(scenario, 500);

//         // liquidate borrower 1
//         liquidate_normal_mode(scenario, *vector::borrow(&borrowers, 1));

//         // check borrower 0 rewards is correct
//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&borrowers, 0), 
//             3044750000000, 
//             1004999999999
//         );

//         // coll price rises
//         set_coll_price(scenario, 1000);

//         // open bottles
//         let debt = get_coin_amount_times_decimal(
//             vector<u64>[500, 500], 
//             decimal_factor()
//         );
//         let icr = vector<u64>[400, 210];
//         let debtors = vector<address>[@0x111, @0x222];
//         open_bottle_by_icr(debt, icr, debtors, scenario);

//         // coll price drop
//         set_coll_price(scenario, 500);

//         // liquidate and check bottle info
//         liquidate_normal_mode(scenario, *vector::borrow(&debtors, 1));

//         // check borrower 0 rewards is correct
//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&borrowers, 0), 
//             3675307027107, 
//             1308282992219
//         );

//         // check debtor 0 rewards is correct
//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&debtors, 0), 
//             2414192972892, 
//             701717007780
//         );

//         test_scenario::end(scenario_val);
//     }

//     #[test]
//     fun test_distributes_correct_rewards_six_open_two_redistribution() {
//         use bucket_protocol::buck::{Self, BUCK, BucketProtocol};
//         use bucket_protocol::bucket;
//         use bucket_protocol::bottle;
//         use bucket_oracle::bucket_oracle::BucketOracle;
//         use bucket_framework::math::mul_factor;
//         use sui::clock::Clock;
//         use sui::sui::SUI;
//         use sui::balance;
        
//         let oracle_price: u64 = 1000;
//         let coll = get_coin_amount_times_decimal(
//             vector<u64>[2000, 2000, 1050], 
//             decimal_factor()
//         );
//         let debt = get_coin_amount_times_decimal(
//             vector<u64>[500, 500, 500], 
//             decimal_factor()
//         );
//         let (scenario_val, borrowers) = setup_customly(
//             oracle_price, 
//             coll, 
//             debt
//         );
//         let scenario = &mut scenario_val;

//         // coll price drop
//         set_coll_price(scenario, 500);

//         // liquidate borrower 2
//         let debtor = *vector::borrow(&borrowers, 2);
//         liquidate_normal_mode(scenario, debtor);

//         // check borrower 0 1 rewards are correct
//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&borrowers, 0), 
//             2522375000000, 
//             753749999999
//         );

//         // check borrower 0 1 rewards are correct
//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&borrowers, 1), 
//             2522375000000, 
//             753749999999
//         );

//         // coll price rises
//         set_coll_price(scenario, 1000);

//         // open bottles
//         let debt = get_coin_amount_times_decimal(
//             vector<u64>[500, 500, 500], 
//             decimal_factor()
//         );
//         let icr = vector<u64>[400, 400, 210];
//         let debtors = vector<address>[@0x111, @0x222, @0x333];
//         open_bottle_by_icr(debt, icr, debtors, scenario);

//         // coll price drop
//         set_coll_price(scenario, 500);

//         // liquidate and check bottle info
//         liquidate_normal_mode(scenario, *vector::borrow(&debtors, 2));

//         // check debtor 0 1 rewards are correct
//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&debtors, 0), 
//             2231017993863, 
//             613614182260
//         );

//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&debtors, 1), 
//             2231017993863, 
//             613614182260
//         );

//         // check borrower 0 1 rewards are correct
//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&borrowers, 0), 
//             2813732006136, 
//             893885817740
//         );

//         check_bottle_info(
//             scenario, 
//             *vector::borrow(&borrowers, 1), 
//             2813732006136, 
//             893885817740
//         );

//         let debtor = *vector::borrow(&debtors, 0);
//         test_scenario::next_tx(scenario, debtor);
//         {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let oracle = test_scenario::take_shared<BucketOracle>(scenario);
//             let clock = test_scenario::take_shared<Clock>(scenario);
//             let sui_amount = 1_000_000;
//             let buck_amount = 1_000_000;
//             let sui_input = balance::create_for_testing<SUI>(sui_amount);
//             let buck_output = buck::borrow<SUI>(&mut protocol, &oracle, &clock, sui_input, buck_amount, std::option::none(), test_scenario::ctx(scenario));
//             assert!(balance::value(&buck_output) == buck_amount, 0);
//             balance::destroy_for_testing(buck_output);
//             test_scenario::return_shared(protocol);
//             test_scenario::return_shared(oracle);
//             test_scenario::return_shared(clock);
//         };

//         test_scenario::next_tx(scenario, dev());
//         {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let (coll_amount, debt_amount) = buck::get_bottle_info_by_debtor<SUI>(&protocol, debtor);
//             let bucket = buck::borrow_bucket<SUI>(&protocol);
//             let bottle_table = bucket::borrow_bottle_table(bucket);
//             let (raw_coll_amount, raw_debt_amount) = bottle::get_bottle_raw_info_by_debator(bottle_table, debtor);

//             assert!(raw_coll_amount == coll_amount, 0);
//             assert!(raw_debt_amount == debt_amount, 0);
//             assert!(coll_amount == 2231017993864 + 1_000_000, 0);
//             assert!(debt_amount == 613614182260 + 1_000_000 * 1005 / 1000, 0);

//             test_scenario::return_shared(protocol);
//         };

//         let debtor = *vector::borrow(&debtors, 1);
//         test_scenario::next_tx(scenario, debtor);
//         {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let clock = test_scenario::take_shared<Clock>(scenario);
//             let sui_amount = 2_000_000;
//             let sui_input = balance::create_for_testing<SUI>(sui_amount);
//             buck::top_up_coll(&mut protocol, sui_input, debtor, std::option::none(), &clock);
//             test_scenario::return_shared(protocol);
//             test_scenario::return_shared(clock);
//         };

//         test_scenario::next_tx(scenario, dev());
//         {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let (coll_amount, debt_amount) = buck::get_bottle_info_by_debtor<SUI>(&protocol, debtor);
//             let bucket = buck::borrow_bucket<SUI>(&protocol);
//             let bottle_table = bucket::borrow_bottle_table(bucket);
//             let (raw_coll_amount, raw_debt_amount) = bottle::get_bottle_raw_info_by_debator(bottle_table, debtor);

//             assert!(raw_coll_amount == coll_amount, 0);
//             assert!(raw_debt_amount == debt_amount, 0);
//             assert!(coll_amount == 2231017993864 + 2_000_000, 0);
//             assert!(debt_amount == 613614182260, 0);
            
//             test_scenario::return_shared(protocol);
//         };

//         let debtor = *vector::borrow(&borrowers, 0);
//         test_scenario::next_tx(scenario, debtor);
//         let (sui_output_amount, buck_input_amount) = {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let clock = test_scenario::take_shared<Clock>(scenario);
//             let buck_input_amount = 3_000_000;
//             let buck_input = balance::create_for_testing<BUCK>(buck_input_amount);
//             let sui_output = buck::repay_debt<SUI>(&mut protocol, buck_input, &clock, test_scenario::ctx(scenario));
//             let sui_output_amount = balance::value(&sui_output);
//             let expected_sui_output_amount =  mul_factor(buck_input_amount, 2813732006136, 893885817740);
//             assert!(sui_output_amount == expected_sui_output_amount, 0);
//             balance::destroy_for_testing(sui_output);
//             test_scenario::return_shared(protocol);
//             test_scenario::return_shared(clock);
//             (sui_output_amount, buck_input_amount)
//         };

//         test_scenario::next_tx(scenario, dev());
//         {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let (coll_amount, debt_amount) = buck::get_bottle_info_by_debtor<SUI>(&protocol, debtor);
//             let bucket = buck::borrow_bucket<SUI>(&protocol);
//             let bottle_table = bucket::borrow_bottle_table(bucket);
//             let (raw_coll_amount, raw_debt_amount) = bottle::get_bottle_raw_info_by_debator(bottle_table, debtor);

//             assert!(raw_coll_amount == coll_amount, 0);
//             assert!(raw_debt_amount == debt_amount, 0);
//             assert!(coll_amount == 2813732006136 - sui_output_amount, 0);
//             assert!(debt_amount == 893885817740 - buck_input_amount, 0);
            
//             test_scenario::return_shared(protocol);
//         };

//         let debtor = *vector::borrow(&borrowers, 1);
//         test_scenario::next_tx(scenario, debtor);
//         {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let oracle = test_scenario::take_shared<BucketOracle>(scenario);
//             let clock = test_scenario::take_shared<Clock>(scenario);
//             let sui_withdrawal_amount = 500_000;
//             let sui_output = buck::withdraw<SUI>(&mut protocol, &oracle, &clock, sui_withdrawal_amount, std::option::none(), test_scenario::ctx(scenario));
//             assert!(balance::value(&sui_output) == sui_withdrawal_amount, 0);
//             balance::destroy_for_testing(sui_output);
//             test_scenario::return_shared(protocol);
//             test_scenario::return_shared(oracle);
//             test_scenario::return_shared(clock);
//         };

//         test_scenario::next_tx(scenario, dev());
//         {
//             let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
//             let (coll_amount, debt_amount) = buck::get_bottle_info_by_debtor<SUI>(&protocol, debtor);
//             let bucket = buck::borrow_bucket<SUI>(&protocol);
//             let bottle_table = bucket::borrow_bottle_table(bucket);
//             let (raw_coll_amount, raw_debt_amount) = bottle::get_bottle_raw_info_by_debator(bottle_table, debtor);

//             assert!(raw_coll_amount == coll_amount, 0);
//             assert!(raw_debt_amount == debt_amount, 0);
//             assert!(coll_amount == 2813732006136 - 500_000, 0);
//             assert!(debt_amount == 893885817740, 0);
            
//             test_scenario::return_shared(protocol);
//         };

//         test_scenario::end(scenario_val);
//     }
// }