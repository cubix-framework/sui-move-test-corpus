module bucket_protocol::bottle {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::option::{Self, Option};
    use std::u64::pow;
    use sui::clock::Clock;
    use sui::dynamic_object_field as dof;

    use bucket_framework::linked_table::{Self, LinkedTable};
    use bucket_framework::math::{mul_factor, mul_factor_u128};
    use bucket_protocol::math::mul_factor_u256;
    use bucket_oracle::bucket_oracle::{Self, BucketOracle};
    use bucket_protocol::constants;
    use bucket_protocol::interest::{Self, InterestTable, BottleInterestIndex};

    friend bucket_protocol::bucket;

    const ECannotRedeemFromBottle: u64 = 1;
    const EDestroyNonEmptyBottle: u64 = 2;
    const EBottleTooSmall: u64 = 3;
    const EBottleNotExists: u64 = 4;
    const EBottleAlreadyExists: u64 = 5;
    const EBottleDebtShouldBeLarger: u64 = 6;
    const EOverflow: u64 = 7;
    const ENotSupportedType: u64 = 8;

    struct BottleTable has store, key {
        id: UID,
        table: LinkedTable<address, Bottle>,
        // redistribution
        total_stake: u64,
        total_stake_snapshot: u64,
        total_collateral_snapshot: u64,
        debt_per_unit_stake: u128,
        reward_per_unit_stake: u128,
        last_reward_error: u128,
        last_debt_error: u128,
    }
    
    struct Bottle has store, key {
        id: UID,
        collateral_amount: u64,
        buck_amount: u64,
        stake_amount: u64,
        reward_coll_snapshot: u128,
        reward_debt_snapshot: u128,
    }

    public(friend) fun new(table: &BottleTable, ctx: &mut TxContext): Bottle {
        Bottle { 
            id: object::new(ctx), 
            collateral_amount: 0, 
            buck_amount: 0, 
            stake_amount: 0, 
            reward_coll_snapshot: table.reward_per_unit_stake, 
            reward_debt_snapshot: table.debt_per_unit_stake 
        }
    }

    public(friend) fun new_table(ctx: &mut TxContext): BottleTable {
        BottleTable {
            id: object::new(ctx),
            table: linked_table::new(ctx),
            total_stake: 0,
            total_stake_snapshot: 0,
            total_collateral_snapshot: 0,
            debt_per_unit_stake: 0,
            reward_per_unit_stake: 0,
            last_reward_error: 0,
            last_debt_error: 0,
        }
    }

    public(friend) fun add_interest_index_to_bottle(
        bottle: &mut Bottle,
        active_interest_index: u256,
        ctx: &mut TxContext,
    ) {
        if (!is_interest_index_exists(bottle)){
            dof::add(&mut bottle.id, b"interest_index", interest::new_bottle_interest_index(active_interest_index, ctx));
        };
    }

    public(friend) fun record_borrow(
        bottle: &mut Bottle,
        collateral_amount: u64,
        buck_amount: u64,
        min_bottle_size: u64,
    ) {
        bottle.collateral_amount = bottle.collateral_amount + collateral_amount;
        bottle.buck_amount = bottle.buck_amount + buck_amount;
        assert!(bottle.buck_amount >= min_bottle_size, EBottleTooSmall);
    }

    public(friend) fun record_top_up(
        bottle: &mut Bottle,
        collateral_amount: u64,
    ) {
        bottle.collateral_amount = bottle.collateral_amount + collateral_amount;
    }

    public(friend) fun record_repay(
        bottle: &mut Bottle, 
        repay_amount: u64, 
        min_bottle_size: u64,
        if_check_debt: bool,
    ): (bool, u64) {
        if (repay_amount >= bottle.buck_amount) {
            let return_sui_amount = bottle.collateral_amount;
            bottle.collateral_amount = 0;
            bottle.buck_amount = 0;

            // fully repaid
            (true, return_sui_amount)

        } else {
            let return_sui_amount = 
                mul_factor(
                    bottle.collateral_amount, 
                    repay_amount, 
                    bottle.buck_amount
                );

            bottle.collateral_amount = bottle.collateral_amount - return_sui_amount;
            bottle.buck_amount = bottle.buck_amount - repay_amount;
            
            if (if_check_debt) {
                assert!(bottle.buck_amount >= min_bottle_size, EBottleTooSmall);
            };

            // not fully repaid
            (false, return_sui_amount)
        }
    }

    public(friend) fun record_withdraw(
        bottle: &mut Bottle,
        collateral_amount: u64,
    ) {
        bottle.collateral_amount = bottle.collateral_amount - collateral_amount;
    }

    fun compute_buck_value_to_collateral(
        buck_amount: u64, 
        collateral_decimal: u8, 
        price: u64, 
        denominator: u64
    ): u64 {

        let buck_raw_value = 
            mul_factor(
                buck_amount, 
                denominator, 
                price
            );

        if (constants::buck_decimal() >= collateral_decimal) {
            buck_raw_value / pow(10, constants::buck_decimal() - collateral_decimal)
        } else {
            buck_raw_value * pow(10, collateral_decimal - constants::buck_decimal())
        }
    }
    
    public(friend) fun record_repay_capped<T>(
        bottle: &mut Bottle, repay_amount: u64, 
        oracle: &BucketOracle, 
        clock: &Clock, mcr: u64, 
        collateral_decimal: u8
    ): (bool, u64) {

        let (price, denominator) = bucket_oracle::get_price<T>(oracle, clock);
        // collateral: at most 110% debt
        let return_sui_amount = 
            compute_buck_value_to_collateral(
                repay_amount * mcr / 100, 
                collateral_decimal, 
                price, 
                denominator
            );

        if (repay_amount >= bottle.buck_amount) {
            if (bottle.collateral_amount < return_sui_amount) {
                return_sui_amount = bottle.collateral_amount;
            };
            bottle.collateral_amount = bottle.collateral_amount - return_sui_amount;
            bottle.buck_amount = 0;

            // fully repaid
            (true, return_sui_amount)

        } else {
            let proportional_sui_amount = 
                mul_factor(
                    bottle.collateral_amount, 
                    repay_amount, 
                    bottle.buck_amount
                );

            if (proportional_sui_amount < return_sui_amount) {
                return_sui_amount = proportional_sui_amount;
            };

            bottle.collateral_amount = bottle.collateral_amount - return_sui_amount;
            bottle.buck_amount = bottle.buck_amount - repay_amount;

            // not fully repaid
            (false, return_sui_amount)
        }
    }

    public(friend) fun record_redeem(
        bottle: &mut Bottle,
        redeemed_amount: u64,
        buck_amount: u64,
    ) {
        assert!(bottle.collateral_amount >= redeemed_amount, ECannotRedeemFromBottle);
        bottle.collateral_amount = bottle.collateral_amount - redeemed_amount;
        bottle.buck_amount = bottle.buck_amount - buck_amount;
    }

    public(friend) fun destroy_surplus_bottle(bottle: Bottle): u64 {
        let Bottle { 
            id, 
            collateral_amount, 
            buck_amount: _, 
            stake_amount: _, 
            reward_coll_snapshot: _, 
            reward_debt_snapshot: _,
        } = bottle;
        object::delete(id);
        collateral_amount
    }

    public(friend) fun remove_bottle_stake(table: &mut BottleTable, debtor: address) {
        let bottle = borrow_bottle_mut(table, debtor);
        let stake_amount = bottle.stake_amount;
        bottle.stake_amount = 0;
        table.total_stake = table.total_stake - stake_amount;
    }
    
    public fun destroy_bottle(table: &mut BottleTable, debtor: address) {
        let bottle = remove_bottle(table, debtor);
        let Bottle { id, collateral_amount, buck_amount, stake_amount, reward_coll_snapshot: _, reward_debt_snapshot: _,} = bottle;
        assert!(collateral_amount == 0 && buck_amount == 0, EDestroyNonEmptyBottle);
        object::delete(id);
        table.total_stake = table.total_stake - stake_amount;
    }

    public fun get_table_length(table: &BottleTable): u64 {
        linked_table::length(borrow_table(table))
    }

    public fun bottle_exists(table: &BottleTable, debtor: address): bool {
        linked_table::contains(&table.table, debtor)
    }

    public fun borrow_bottle(table: &BottleTable, debtor: address): &Bottle {
        assert!(linked_table::contains(&table.table, debtor), EBottleNotExists);
        linked_table::borrow(&table.table, debtor)
    }

    public(friend) fun borrow_bottle_mut(table: &mut BottleTable, debtor: address): &mut Bottle {
        assert!(linked_table::contains(&table.table, debtor), EBottleNotExists);
        linked_table::borrow_mut(&mut table.table, debtor)
    }

    public fun borrow_interest_index(bottle: &Bottle): &BottleInterestIndex {
        assert!(is_interest_index_exists(bottle), ENotSupportedType);
        dof::borrow<vector<u8>, BottleInterestIndex>(&bottle.id, b"interest_index")
    }


    public(friend) fun borrow_interest_index_mut(bottle: &mut Bottle): &mut BottleInterestIndex {
        assert!(is_interest_index_exists(bottle), ENotSupportedType);
        dof::borrow_mut<vector<u8>, BottleInterestIndex>(&mut bottle.id, b"interest_index")
    }

    public(friend) fun remove_bottle(table: &mut BottleTable, debtor: address): Bottle {
        assert!(linked_table::contains(&table.table, debtor), EBottleNotExists);
        linked_table::remove(&mut table.table, debtor)
    }

    public(friend) fun pop_front(table: &mut BottleTable): (address, Bottle) {
        assert!(option::is_some(linked_table::front(&table.table)), EBottleNotExists);
        linked_table::pop_front(&mut table.table)
    }

    public fun get_lowest_cr_debtor(table: &BottleTable): Option<address> {
        *linked_table::front(&table.table)
    }

    public fun get_bottle_info(table: &BottleTable, bottle: &Bottle): (u64, u64) {
        let pending_coll = get_pending_coll(bottle, table);
        let pending_debt = get_pending_debt(bottle, table);

        (bottle.collateral_amount + pending_coll, bottle.buck_amount + pending_debt)
    }

    public fun get_bottle_info_by_debtor(table: &BottleTable, debtor: address): (u64, u64) {
        let bottle = borrow_bottle(table, debtor);
        let pending_coll = get_pending_coll(bottle, table);
        let pending_debt = get_pending_debt(bottle, table);

        (bottle.collateral_amount + pending_coll, bottle.buck_amount + pending_debt)
    }

    public fun get_bottle_raw_info_by_debator(table: &BottleTable, debtor: address): (u64, u64) {
        let bottle = borrow_bottle(table, debtor);
        (bottle.collateral_amount, bottle.buck_amount)
    }
    
    public fun get_bottle_raw_info(bottle: &Bottle): (u64, u64) {
        (bottle.collateral_amount, bottle.buck_amount)
    }
   
    // get bottle info with interest
    public fun get_bottle_info_with_interest(table: &BottleTable, bottle: &Bottle, interest_table: &InterestTable, clock: &Clock): (u64, u64) {
        let pending_coll = get_pending_coll(bottle, table);
        let pending_debt = get_pending_debt(bottle, table);
        let debt = get_debt_amount_with_interest(bottle, interest_table, bottle.buck_amount, clock);

        (bottle.collateral_amount + pending_coll, debt + pending_debt)
    }
    
    // get bottle info with interest
    public fun get_bottle_info_with_interest_by_debtor(table: &BottleTable, debtor: address, interest_table: &InterestTable, clock: &Clock): (u64, u64) {
        let bottle = borrow_bottle(table, debtor);
        let pending_coll = get_pending_coll(bottle, table);
        let pending_debt = get_pending_debt(bottle, table);
        let debt = get_debt_amount_with_interest(bottle, interest_table, bottle.buck_amount, clock);

        (bottle.collateral_amount + pending_coll, debt + pending_debt)
    }

    fun get_debt_amount_with_interest(bottle: &Bottle, interest_table: &InterestTable, buck_amount: u64, clock: &Clock): u64 {
        if (is_interest_index_exists(bottle)) {
            let debt = (buck_amount as u256);
            let bottle_interest_index_object = borrow_interest_index(bottle);
            let bottle_interest_index = interest::get_bottle_interest_index(bottle_interest_index_object);
            
            if (bottle_interest_index > 0) {
                let (current_index, _) = interest::calculate_interest_index(interest_table, clock);
                debt = mul_factor_u256((debt as u256), current_index, bottle_interest_index);
            };

            assert!(debt <= (constants::max_u64() as u256), EOverflow);

            (debt as u64)
        } else {
            buck_amount
        }
    }

    public fun get_pending_coll(bottle: &Bottle, table: &BottleTable): u64 {
        (mul_factor_u128(
            (bottle.stake_amount as u128), 
            (table.reward_per_unit_stake - bottle.reward_coll_snapshot as u128),  
            constants::distribution_precision()
        ) as u64)
    }

    public fun get_pending_debt(bottle: &Bottle, table: &BottleTable): u64 {
        (mul_factor_u128(
            (bottle.stake_amount as u128), 
            (table.debt_per_unit_stake - bottle.reward_debt_snapshot as u128), 
            constants::distribution_precision()
        ) as u64)
    }

    public fun borrow_table(table: &BottleTable): &LinkedTable<address, Bottle> {
        &table.table
    }

    // update pending coll and debt to bottle
    public(friend) fun get_bottle_info_after_update(table: &mut BottleTable, debtor: address): (u64, u64) {
        let table_reward_per_unit_stake = table.reward_per_unit_stake;
        let table_debt_per_unit_stake = table.debt_per_unit_stake;
        let bottle = borrow_bottle(table, debtor);
        let pending_coll = get_pending_coll(bottle, table);
        let pending_debt = get_pending_debt(bottle, table);
        
        let bottle = borrow_bottle_mut(table, debtor);
        bottle.collateral_amount = bottle.collateral_amount + pending_coll;
        bottle.buck_amount = bottle.buck_amount + pending_debt;
        bottle.reward_coll_snapshot = table_reward_per_unit_stake;
        bottle.reward_debt_snapshot = table_debt_per_unit_stake;
        
        (bottle.collateral_amount, bottle.buck_amount)
    }

    public(friend) fun update_snapshot(table: &mut BottleTable, collateral_vault_balance: u64) {
        table.total_stake_snapshot = table.total_stake;
        table.total_collateral_snapshot = collateral_vault_balance;
    }

    public(friend) fun update_bottle_debt_and_interest_index(bottle: &mut Bottle, buck_debt_amount: u64, active_interest_index: u256) {
        assert!(bottle.buck_amount <= buck_debt_amount, EBottleDebtShouldBeLarger);
        if (is_interest_index_exists(bottle)) {
            bottle.buck_amount = buck_debt_amount;
            let bottle_interest_index = borrow_interest_index_mut(bottle);
            interest::update_bottle_interest_index(bottle_interest_index, active_interest_index);
        };
    }

    public(friend) fun update_stake_and_total_stake(table: &mut BottleTable, bottle: &mut Bottle) {

        let (collateral_amount, _) = get_bottle_raw_info(bottle);
        let new_stake_amount = compute_new_stake(table, collateral_amount);
        
        table.total_stake = 
            table.total_stake + 
            new_stake_amount - 
            bottle.stake_amount;
        bottle.stake_amount = new_stake_amount;
    }

    public(friend) fun update_stake_and_total_stake_by_debtor(table: &mut BottleTable, debtor: address) {

        let (collateral_amount, _) = get_bottle_raw_info_by_debator(table, debtor);
        let new_stake_amount = compute_new_stake(table, collateral_amount);
        let bottle = borrow_bottle_mut(table, debtor);
        let bottle_stake_amount = bottle.stake_amount;
        
        bottle.stake_amount = new_stake_amount;
        table.total_stake = 
            table.total_stake + 
            new_stake_amount - 
            bottle_stake_amount;
    }

    public(friend) fun new_surplus_bottle(
        collateral_amount: u64,
        ctx: &mut TxContext,
    ): Bottle {
        Bottle {
            id: object::new(ctx),
            collateral_amount,
            buck_amount: 0,
            stake_amount: 0,
            reward_coll_snapshot: 0,
            reward_debt_snapshot: 0,
        }
    }

    fun compute_new_stake(table: &BottleTable, collateral_amount: u64): u64 {
        if (table.total_collateral_snapshot == 0) {
            collateral_amount
        } else {
            mul_factor(
                collateral_amount, 
                table.total_stake_snapshot, 
                table.total_collateral_snapshot
            )
        }
    }

    public(friend) fun record_redistribution(
        table: &mut BottleTable,
        collateral_amount: u64,
        debt_amount: u64,
        debtor: address,
    ) {
        
        let total_stake = (table.total_stake as u128);
        
        let reward_numerator = 
            mul_factor_u128(
                (collateral_amount as u128), 
                constants::distribution_precision(), 
                1
            ) + table.last_reward_error;
        let debt_numerator = 
            mul_factor_u128(
            (debt_amount as u128), 
                constants::distribution_precision(), 
                1
            ) + table.last_debt_error;

        let reward_per_unit_stake_cache = reward_numerator / total_stake;
        let debt_per_unit_stake_cache = debt_numerator /  total_stake;

        table.last_reward_error = reward_numerator - reward_per_unit_stake_cache * total_stake;
        table.last_debt_error = debt_numerator - debt_per_unit_stake_cache * total_stake;
        
        table.reward_per_unit_stake = table.reward_per_unit_stake + reward_per_unit_stake_cache;
        table.debt_per_unit_stake = table.debt_per_unit_stake + debt_per_unit_stake_cache;
        
        let bottle = borrow_bottle_mut(table, debtor);
        bottle.buck_amount = 0;
        bottle.collateral_amount = 0;
        bottle.reward_coll_snapshot = 0;
        bottle.reward_debt_snapshot = 0;
    }

    public(friend) fun insert(
        table: &mut BottleTable,
        debtor: address,
        bottle: Bottle,
        insertion_place: Option<address>,
    ) {
        if (option::is_none(&insertion_place)) {
            let back_debtor_opt = *linked_table::front(&table.table);
            find_upward_and_insert(table, debtor, bottle, back_debtor_opt);
            return
        } else {
            let start_debtor = option::destroy_some(insertion_place);
            assert!(!linked_table::contains(&table.table, debtor), EBottleAlreadyExists);
            let start_bottle = linked_table::borrow(&table.table, start_debtor);
            if (cr_greater(table, &bottle, start_bottle)) {
                let next_debtor = *linked_table::next(&table.table, start_debtor);
                find_upward_and_insert(table, debtor, bottle, next_debtor);
            } else {
                let prev_debtor = *linked_table::prev(&table.table, start_debtor);
                find_downward_and_insert(table, debtor, bottle, prev_debtor);
            }
        }
    }

    public(friend) fun insert_bottle(
        table: &mut BottleTable,
        interest_table: &InterestTable,
        debtor: address,
        bottle: Bottle,
        insertion_place: Option<address>,
        clock: &Clock,
    ) {
        if (option::is_none(&insertion_place)) {
            let back_debtor_opt = *linked_table::front(&table.table);
            find_upward_and_insert_with_interest(table, interest_table, debtor, bottle, back_debtor_opt, clock);
            return
        } else {
            let start_debtor = option::destroy_some(insertion_place);
            assert!(!linked_table::contains(&table.table, debtor), EBottleAlreadyExists);
            let start_bottle = linked_table::borrow(&table.table, start_debtor);
            if (cr_greater_with_interest(table, interest_table, &bottle, start_bottle, clock)) {
                let next_debtor = *linked_table::next(&table.table, start_debtor);
                find_upward_and_insert_with_interest(table, interest_table, debtor, bottle, next_debtor, clock);
            } else {
                let prev_debtor = *linked_table::prev(&table.table, start_debtor);
                find_downward_and_insert_with_interest(table, interest_table, debtor, bottle, prev_debtor, clock);
            }
        }
    }

    fun find_upward_and_insert_with_interest(
        table: &mut BottleTable,
        interest_table: &InterestTable,
        debtor: address,
        bottle: Bottle,
        curr_debtor_opt: Option<address>,
        clock: &Clock,
    ) {
        while (option::is_some(&curr_debtor_opt)) {
            let curr_debtor = *option::borrow(&curr_debtor_opt);
            let curr_bottle = linked_table::borrow(&table.table, curr_debtor);
            if (cr_less_or_equal_with_interest(table, interest_table,&bottle, curr_bottle, clock)) {
                linked_table::insert_front(&mut table.table, curr_debtor_opt, debtor, bottle);
                return
            };
            curr_debtor_opt = *linked_table::next(&table.table, curr_debtor);
        };
        linked_table::insert_front(&mut table.table, curr_debtor_opt, debtor, bottle);
    }

    fun find_upward_and_insert(
        table: &mut BottleTable,
        debtor: address,
        bottle: Bottle,
        curr_debtor_opt: Option<address>,
    ) {
        while (option::is_some(&curr_debtor_opt)) {
            let curr_debtor = *option::borrow(&curr_debtor_opt);
            let curr_bottle = linked_table::borrow(&table.table, curr_debtor);
            if (cr_less_or_equal(table, &bottle, curr_bottle)) {
                linked_table::insert_front(&mut table.table, curr_debtor_opt, debtor, bottle);
                return
            };
            curr_debtor_opt = *linked_table::next(&table.table, curr_debtor);
        };
        linked_table::insert_front(&mut table.table, curr_debtor_opt, debtor, bottle);
    }

    fun find_downward_and_insert(
        table: &mut BottleTable,
        debtor: address,
        bottle: Bottle,
        curr_debtor_opt: Option<address>,
    ) {
        while (option::is_some(&curr_debtor_opt)) {
            let curr_debtor = *option::borrow(&curr_debtor_opt);
            let curr_bottle = linked_table::borrow(&table.table, curr_debtor);
            if (cr_greater(table, &bottle, curr_bottle)) {
                linked_table::insert_back(&mut table.table, curr_debtor_opt, debtor, bottle);
                return
            };
            curr_debtor_opt = *linked_table::prev(&table.table, curr_debtor);
        };
        linked_table::insert_back(&mut table.table, curr_debtor_opt, debtor, bottle);
    }

    fun find_downward_and_insert_with_interest(
        table: &mut BottleTable,
        interest_table: &InterestTable,
        debtor: address,
        bottle: Bottle,
        curr_debtor_opt: Option<address>,
        clock: &Clock,
    ) {
        while (option::is_some(&curr_debtor_opt)) {
            let curr_debtor = *option::borrow(&curr_debtor_opt);
            let curr_bottle = linked_table::borrow(&table.table, curr_debtor);
            if (cr_greater_with_interest(table, interest_table, &bottle, curr_bottle, clock)) {
                linked_table::insert_back(&mut table.table, curr_debtor_opt, debtor, bottle);
                return
            };
            curr_debtor_opt = *linked_table::prev(&table.table, curr_debtor);
        };
        linked_table::insert_back(&mut table.table, curr_debtor_opt, debtor, bottle);
    }

    public fun cr_greater(table: &BottleTable, bottle: &Bottle, bottle_cmp: &Bottle): bool {
        let (bottle_coll_amount, bottle_buck_amount) = get_bottle_info(table, bottle);
        let (bottle_coll_amount_cmp, bottle_buck_amount_cmp) = get_bottle_info(table, bottle_cmp);
        (bottle_coll_amount as u128) * (bottle_buck_amount_cmp as u128) >
            (bottle_coll_amount_cmp as u128) * (bottle_buck_amount as u128)
    }

    public fun cr_greater_with_interest(table: &BottleTable, interest_table: &InterestTable, bottle: &Bottle, bottle_cmp: &Bottle, clock: &Clock): bool {
        let (bottle_coll_amount, bottle_buck_amount) = 
            if (is_interest_index_exists(bottle)) {
                get_bottle_info_with_interest(table, bottle, interest_table, clock)
            } else {
                get_bottle_info(table, bottle)
            };
        let (bottle_coll_amount_cmp, bottle_buck_amount_cmp) = 
            if (is_interest_index_exists(bottle_cmp)) {
                get_bottle_info_with_interest(table, bottle_cmp, interest_table, clock)
            } else {
                get_bottle_info(table, bottle_cmp)
            };
        (bottle_coll_amount as u128) * (bottle_buck_amount_cmp as u128) >
            (bottle_coll_amount_cmp as u128) * (bottle_buck_amount as u128)
    }

    public fun cr_less_or_equal(table: &BottleTable, bottle: &Bottle, bottle_cmp: &Bottle): bool {
        let (bottle_coll_amount, bottle_buck_amount) = get_bottle_info(table, bottle);
        let (bottle_coll_amount_cmp, bottle_buck_amount_cmp) = get_bottle_info(table, bottle_cmp);
        (bottle_coll_amount as u128) * (bottle_buck_amount_cmp as u128) <=
            (bottle_coll_amount_cmp as u128) * (bottle_buck_amount as u128)
    }

    public fun cr_less_or_equal_with_interest(table: &BottleTable, interest_table: &InterestTable, bottle: &Bottle, bottle_cmp: &Bottle, clock: &Clock): bool {
        let (bottle_coll_amount, bottle_buck_amount) = 
            if (is_interest_index_exists(bottle)) {
                get_bottle_info_with_interest(table, bottle, interest_table, clock)
            } else {
                get_bottle_info(table, bottle)
            };
        let (bottle_coll_amount_cmp, bottle_buck_amount_cmp) = 
            if (is_interest_index_exists(bottle_cmp)) {
                get_bottle_info_with_interest(table, bottle_cmp, interest_table, clock)
            } else {
                get_bottle_info(table, bottle_cmp)
            };
        (bottle_coll_amount as u128) * (bottle_buck_amount_cmp as u128) <=
            (bottle_coll_amount_cmp as u128) * (bottle_buck_amount as u128)
    }

    public fun re_insert(table: &mut BottleTable, debtor: address) {
        let prev_debtor = *linked_table::prev(&table.table, debtor);
        let bottle = linked_table::remove(&mut table.table, debtor);
        insert(table, debtor, bottle, prev_debtor);
    }

    public fun re_insert_bottle(table: &mut BottleTable, interest_table: &InterestTable, debtor: address, clock: &Clock) {
        let prev_debtor = *linked_table::prev(&table.table, debtor);
        let bottle = linked_table::remove(&mut table.table, debtor);
        insert_bottle(table, interest_table, debtor, bottle, prev_debtor, clock);
    }

    public fun is_interest_index_exists(bottle: &Bottle): bool {
        dof::exists_<vector<u8>>(&bottle.id, b"interest_index")
    }

    #[test_only]
    public fun print_bottle(bottle: &Bottle) {
        if (bottle.buck_amount == 0) {
            std::debug::print(&0);
        } else {
            std::debug::print(&(mul_factor(bottle.collateral_amount, 100, bottle.buck_amount)));
        };
        std::debug::print(bottle);
    }

    #[test_only]
    public fun check_bottle_order_in_bucket(table: &BottleTable, if_print: bool): u64 {
        let debtor_opt = *linked_table::front(&table.table);
        while(option::is_some(&debtor_opt)) {
            let curr_debtor = *option::borrow(&debtor_opt);
            let curr_bottle = linked_table::borrow(&table.table, curr_debtor);
            if (if_print) print_bottle(curr_bottle);
            let next_debtor_opt = linked_table::next(&table.table, curr_debtor);
            if (option::is_some(next_debtor_opt)) {
                let next_debtor = *option::borrow(next_debtor_opt);
                let next_bottle = linked_table::borrow(&table.table, next_debtor);
                assert!(cr_less_or_equal(table, curr_bottle, next_bottle), 0);
            };
            debtor_opt = *next_debtor_opt;
        };
        linked_table::length(&table.table)
    }

}
