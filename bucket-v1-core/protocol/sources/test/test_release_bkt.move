#[test_only]
module bucket_protocol::release_bkt {
    use std::vector;
    use sui::sui::SUI;
    use sui::balance;
    use sui::test_scenario;
    use bucket_protocol::tank::{Self, ContributorToken};
    use bucket_protocol::buck::{Self, BUCK, BucketProtocol, AdminCap};
    use bucket_protocol::bkt::{Self, BktTreasury};
    use bucket_protocol::test_utils::{setup_empty, deposit_buck_to_tank, dev};

    #[test]
    fun test_release_bkt() {
        let oracle_price = 770;
        let scenario_val = setup_empty(oracle_price);
        let scenario = &mut scenario_val;

        let depositors = vector<address>[
            @0xc0, @0xc1, @0xc2, @0xc3, @0xc4, @0xc5, @0xc6, @0xc7, @0xc8
        ];

        let deposit_amount = vector<u64>[
            1_000_000_000,
            2_000_000_000,
            3_000_000_000,
            4_000_000_000,
            6_000_000_000,
            7_000_000_000,
            8_000_000_000,
            9_000_000_000,
            60_000_000_000,
        ];

        deposit_buck_to_tank(scenario, depositors, deposit_amount);
        
        let release_amount: u64 = 10_000_000;
        test_scenario::next_tx(scenario, dev());
        let init_eco_balance = {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            
            let tank = buck::borrow_tank<SUI>(&protocol);
            assert!(tank::get_reserve_balance(tank) == 100_000_000_000, 0);
            assert!(tank::get_bkt_pool_balance(tank) == 0, 0);
            let init_eco_balance = bkt::get_eco_part_balance(&bkt_treasury);
            buck::release_bkt<SUI>(&admin_cap, &mut protocol, &mut bkt_treasury, release_amount);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(bkt_treasury);
            test_scenario::return_to_sender(scenario, admin_cap);

            init_eco_balance
        };

        let contributor = *vector::borrow(&depositors, 5);
        test_scenario::next_tx(scenario, contributor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            assert!(tank::get_bkt_pool_balance(tank) == release_amount, 0);
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            assert!(tank::get_bkt_reward_amount(tank, &token) == release_amount * 7 / 100, 0);
            let (coll_reward, bkt_reward) = tank::claim(tank, &mut bkt_treasury, &mut token, test_scenario::ctx(scenario));
            balance::destroy_zero(coll_reward);
            balance::destroy_zero(bkt_reward);
            assert!(bkt::get_eco_part_balance(&bkt_treasury) == init_eco_balance - release_amount * 93 / 100, 0);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(bkt_treasury);
            test_scenario::return_to_sender(scenario, token);
       };

        let second_release_amount: u64 = 15_000_000;
        test_scenario::next_tx(scenario, dev());
        let second_eco_balance = {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            
            let tank = buck::borrow_tank<SUI>(&protocol);
            assert!(tank::get_reserve_balance(tank) == 100_000_000_000, 0);
            assert!(tank::get_bkt_pool_balance(tank) == release_amount * 93 / 100, 0);
            let second_eco_balance = bkt::get_eco_part_balance(&bkt_treasury);
            buck::release_bkt<SUI>(&admin_cap, &mut protocol, &mut bkt_treasury, second_release_amount);

            test_scenario::return_shared(protocol);
            test_scenario::return_shared(bkt_treasury);
            test_scenario::return_to_sender(scenario, admin_cap);

            second_eco_balance
        };

        test_scenario::next_epoch(scenario, contributor); {};
        test_scenario::next_epoch(scenario, contributor); {};
        test_scenario::next_epoch(scenario, contributor); {};
        test_scenario::next_epoch(scenario, contributor); {};
        test_scenario::next_epoch(scenario, contributor); {};
        test_scenario::next_epoch(scenario, contributor); {};
        test_scenario::next_epoch(scenario, contributor); {};
        test_scenario::next_epoch(scenario, contributor); {};

        test_scenario::next_tx(scenario, contributor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            assert!(tank::get_bkt_pool_balance(tank) == release_amount * 93 / 100 + second_release_amount, 0);
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            // std::debug::print(&tank::get_bkt_reward_amount(tank, &token));
            // std::debug::print(&(second_release_amount * 7 / 100));
            assert!(tank::get_bkt_reward_amount(tank, &token) == second_release_amount * 7 / 100, 0);
            let (coll_reward, bkt_reward) = tank::claim(tank, &mut bkt_treasury, &mut token, test_scenario::ctx(scenario));
            balance::destroy_zero(coll_reward);
            // std::debug::print(&balance::value(&bkt_reward));
            assert!(balance::value(&bkt_reward) == second_release_amount * 7 / 100, 0);
            assert!(bkt::get_eco_part_balance(&bkt_treasury) == second_eco_balance - second_release_amount, 0);
            balance::destroy_for_testing(bkt_reward);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(bkt_treasury);
            test_scenario::return_to_sender(scenario, token);
        };

        test_scenario::next_tx(scenario, contributor);
        {
            let protocol = test_scenario::take_shared<BucketProtocol>(scenario);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            let tank = buck::borrow_tank_mut<SUI>(&mut protocol);
            let token = test_scenario::take_from_sender<ContributorToken<BUCK, SUI>>(scenario);
            assert!(tank::get_bkt_reward_amount(tank, &token) == 0, 0);
            assert!(tank::get_bkt_pool_balance(tank) == (release_amount + second_release_amount) * 93 / 100, 0);
            test_scenario::return_shared(protocol);
            test_scenario::return_shared(bkt_treasury);
            test_scenario::return_to_sender(scenario, token);
        };

        test_scenario::end(scenario_val);
    }
}