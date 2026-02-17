module bucket_protocol::bucket {

    use std::u64::pow;
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::TxContext;
    use sui::clock::Clock;
    use sui::table::{Self, Table};
    use std::option::{Self, Option};
    use sui::dynamic_object_field as dof;

    use bucket_framework::math::mul_factor;
    use bucket_protocol::math::mul_factor_u256;
    use bucket_framework::linked_table;
    use bucket_oracle::bucket_oracle::{Self, BucketOracle};
    use bucket_protocol::bottle::{Self, Bottle, BottleTable};
    use bucket_protocol::constants;
    use bucket_protocol::bucket_events as events;
    use bucket_protocol::interest::{Self, InterestTable};

    friend bucket_protocol::buck;

    const EBucketLocked: u64 = 0;
    const ERepayTooMuch: u64 = 1;
    const EFlashFeeNotEnough: u64 = 2;
    const ENotEnoughToRedeem: u64 = 3;
    const EBottleIsNotHealthy: u64 = 4;
    const ECannotExceedMintCap: u64 = 5;
    const ESurplusBottleNotFound: u64 = 6;
    const ENotSupportedType: u64 = 7;
    const EOverflow: u64 = 8;
    const ECannotDestroyNonEmptyStrap: u64 = 8;

    struct Bucket<phantom T> has key, store {
        id: UID,
        // settings
        min_collateral_ratio: u64,
        recovery_mode_threshold: u64,
        collateral_decimal: u8,
        max_mint_amount: Option<u64>,
        // handle collateral
        collateral_vault: Balance<T>,
        bottle_table: BottleTable,
        surplus_bottle_table: Table<address, Bottle>,
        // recording
        minted_buck_amount: u64,
        base_fee_rate: u64,
        latest_redemption_time: u64,
        total_flash_loan_amount: u64,
    }

    // record for redistribution
    struct PendingRecord has key, store {
        id: UID,
        bucket_pending_debt: u64,
        bucket_pending_collateral: u64,
    }

    struct FlashReceipt<phantom T> {
        amount: u64,
        fee: u64,
    }

    public(friend) fun new<T>(
        min_collateral_ratio: u64,
        recovery_mode_threshold: u64,
        collateral_decimal: u8,
        max_mint_amount: Option<u64>,
        ctx: &mut TxContext,
    ): Bucket<T> {
        let id = object::new(ctx);
        dof::add(&mut id, b"pending_record", new_pending_record(ctx));
        Bucket {
            id: id,
            min_collateral_ratio,
            recovery_mode_threshold,
            collateral_decimal,
            max_mint_amount,
            collateral_vault: balance::zero(),
            bottle_table: bottle::new_table(ctx),
            surplus_bottle_table: table::new(ctx),
            minted_buck_amount: 0,
            base_fee_rate: 0,
            latest_redemption_time: 0,
            total_flash_loan_amount: 0,
        }
    }

    public(friend) fun new_pending_record(ctx: &mut TxContext): PendingRecord {
        PendingRecord {
            id: object::new(ctx),
            bucket_pending_debt: 0,
            bucket_pending_collateral: 0,
        }
    }

    public(friend) fun add_pending_record_to_bucket<T>(bucket: &mut Bucket<T>, ctx: &mut TxContext) {
        let name = b"pending_record";
        if (!dof::exists_with_type<vector<u8>, PendingRecord>(&bucket.id, name))
            dof::add(&mut bucket.id, name, new_pending_record(ctx));
    }

    // Add interest table to the bucket, if the bucket does not have the interest table
    public(friend) fun add_interest_table_to_bucket<T>(
        bucket: &mut Bucket<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        dof::add(&mut bucket.id, b"interest_table", interest::new_interest_table(clock, ctx));
    }

    public(friend) fun add_interest_index_to_bottle(
        bottle: &mut Bottle,
        active_interest_index: u256,
        ctx: &mut TxContext,
    ) {

        bottle::add_interest_index_to_bottle(bottle, active_interest_index, ctx);
    }

    public(friend) fun add_interest_index_to_bottle_by_debtor<T>(
        bucket: &mut Bucket<T>,
        debtor: address,
        active_interest_index: u256,
        ctx: &mut TxContext,
    ) {
        let bottle_table = &mut bucket.bottle_table;
        let bottle = bottle::borrow_bottle_mut(bottle_table, debtor);
        bottle::add_interest_index_to_bottle(bottle, active_interest_index, ctx);
    }

    public fun borrow_interest_table<T>(bucket: &Bucket<T>): &InterestTable {
        assert!(is_interest_table_exists(bucket), ENotSupportedType);
        dof::borrow<vector<u8>, InterestTable>(&bucket.id, b"interest_table")
    }

    public(friend) fun borrow_interest_table_mut<T>(bucket: &mut Bucket<T>): &mut InterestTable {
        assert!(is_interest_table_exists(bucket), ENotSupportedType);
        dof::borrow_mut<vector<u8>, InterestTable>(&mut bucket.id, b"interest_table")
    }

    // add interests to bottle & bucket
    // @todo check if accrue the interest of pending debt? -> accrue before redistribution
    // 1. accrue all interests
    // 2. update bottle interest table
    // 3. update bottle debt
    public(friend) fun accrue_interests_by_debtor<T>(bucket: &mut Bucket<T>, debtor: address, clock: &Clock): u64 {
        let minted_buck_amount = bucket.minted_buck_amount;
        let bucket_pending_debt = borrow_pending_record(bucket).bucket_pending_debt;
        let (_, bottle_debt) = bottle::get_bottle_raw_info_by_debator(&bucket.bottle_table, debtor);
        let bottle = bottle::borrow_bottle(&bucket.bottle_table, debtor);
        if (bottle::is_interest_index_exists(bottle)) {
            let bottle_interest_index_object = bottle::borrow_interest_index(bottle);
            let bottle_interest_index = interest::get_bottle_interest_index(bottle_interest_index_object);
            let interest_table = borrow_interest_table_mut(bucket);
            let (current_interest_index, bucket_interest_amount) =
                interest::accrue_active_interests(
                    interest_table,
                    minted_buck_amount - bucket_pending_debt,
                    clock
                );

            if (bottle_interest_index < current_interest_index) {
                // calculate the debt after updating the interest
                let debt = mul_factor_u256((bottle_debt as u256), current_interest_index, bottle_interest_index);
                assert!(debt <= (constants::max_u64() as u256), EOverflow);
                bottle_debt = (debt as u64);
                let active_interest_index = interest::get_active_interest_index(interest_table);
                // update bottle interest table
                let bottle = bottle::borrow_bottle_mut(&mut bucket.bottle_table, debtor);
                bottle::update_bottle_debt_and_interest_index(bottle, bottle_debt, active_interest_index);
            };

            assert!(bucket_interest_amount <= (constants::max_u64() as u256), EOverflow);
            bucket.minted_buck_amount = bucket.minted_buck_amount + (bucket_interest_amount as u64);

            (bucket_interest_amount as u64)

        } else {
            0
        }
    }

    public(friend) fun handle_borrow<T>(
        bucket: &mut Bucket<T>,
        oracle: &BucketOracle,
        borrower: address,
        clock: &Clock,
        collateral_input: Balance<T>,
        buck_output_amount: u64,
        insertion_place: Option<address>,
        min_bottle_size: u64,
        ctx: &mut TxContext,
    ) {
        check_insertion_place(bucket, borrower, &mut insertion_place);
        assert!(is_not_locked(bucket), EBucketLocked);
        let is_new_bottle = false;
        let collateral_input_amount = balance::value(&collateral_input);
        let bottle = if(bottle_exists(bucket, borrower)) {
            if (is_interest_table_exists(bucket)) {
                accrue_interests_by_debtor(bucket, borrower, clock);
            };
            apply_pending(bucket, borrower);
            bottle::remove_bottle(&mut bucket.bottle_table, borrower)
        } else if (table::contains(&bucket.surplus_bottle_table, borrower)) {
            let surplus_bottle = table::remove(&mut bucket.surplus_bottle_table, borrower);
            let surplus_collateral_amount = bottle::destroy_surplus_bottle(surplus_bottle);
            collateral_input_amount = collateral_input_amount + surplus_collateral_amount;
            let table = borrow_bottle_table(bucket);
            bottle::new(table, ctx)
        } else {
            is_new_bottle = true;
            let table = borrow_bottle_table(bucket);
            bottle::new(table, ctx)
        };

        // add bottle interest index
        if (is_interest_table_exists(bucket) && !bottle_exists(bucket, borrower)) {
            let interest_table = borrow_interest_table(bucket);
            let active_interest_index = interest::get_active_interest_index(interest_table);
            add_interest_index_to_bottle(&mut bottle, active_interest_index, ctx);
        };

        bottle::record_borrow(&mut bottle, collateral_input_amount, buck_output_amount, min_bottle_size);

        // update stake and total stake when create bottle and adjust bottle
        bottle::update_stake_and_total_stake(&mut bucket.bottle_table, &mut bottle);

        if (is_new_bottle) {
            events::emit_bottle_created<T>(borrower, &bottle);
        } else {
            events::emit_bottle_updated<T>(borrower, &bottle);
        };

        bucket.minted_buck_amount = bucket.minted_buck_amount + buck_output_amount;
        balance::join(&mut bucket.collateral_vault, collateral_input);
        assert!(!is_in_recovery_mode(bucket, oracle, clock), EBottleIsNotHealthy);
        assert!(is_healthy_bottle(bucket, oracle, clock, &bottle), EBottleIsNotHealthy);
        if (option::is_some(&bucket.max_mint_amount)) {
            let max_mint_amount = *option::borrow(&bucket.max_mint_amount);
            assert!(bucket.minted_buck_amount <= max_mint_amount, ECannotExceedMintCap);
        };

        if (is_interest_table_exists(bucket)) {
            let interest_table = dof::remove<vector<u8>, InterestTable>(&mut bucket.id, b"interest_table");
            bottle::insert_bottle(&mut bucket.bottle_table, &interest_table, borrower, bottle, insertion_place, clock);
            dof::add(&mut bucket.id, b"interest_table", interest_table);
        } else {
            bottle::insert(&mut bucket.bottle_table, borrower, bottle, insertion_place);
        };
    }

    public(friend) fun handle_top_up<T>(
        bucket: &mut Bucket<T>,
        collateral_input: Balance<T>,
        debtor: address,
        insertion_place: Option<address>,
        clock: &Clock,
    ) {
        check_insertion_place(bucket, debtor, &mut insertion_place);
        apply_pending(bucket, debtor);
        let bottle = bottle::remove_bottle(&mut bucket.bottle_table, debtor);
        let collateral_amount = balance::value(&collateral_input);
        bottle::record_top_up(&mut bottle, collateral_amount);
        bottle::update_stake_and_total_stake(&mut bucket.bottle_table, &mut bottle);
        events::emit_bottle_updated<T>(debtor, &bottle);
        if (is_interest_table_exists(bucket)) {
            let interest_table = dof::remove<vector<u8>, InterestTable>(&mut bucket.id, b"interest_table");
            bottle::insert_bottle(&mut bucket.bottle_table, &interest_table, debtor, bottle, insertion_place, clock);
            dof::add(&mut bucket.id, b"interest_table", interest_table);
        } else {
            bottle::insert(&mut bucket.bottle_table, debtor, bottle, insertion_place);
        };
        balance::join(&mut bucket.collateral_vault, collateral_input);
    }

    public(friend) fun handle_withdraw<T>(
        bucket: &mut Bucket<T>,
        oracle: &BucketOracle,
        debtor: address,
        clock: &Clock,
        collateral_amount: u64,
        insertion_place: Option<address>,
    ): Balance<T> {
        // accrue interest
        if (is_interest_table_exists(bucket)) {
            accrue_interests_by_debtor(bucket, debtor, clock);
        };
        check_insertion_place(bucket, debtor, &mut insertion_place);
        apply_pending(bucket, debtor);
        let bottle = bottle::remove_bottle(&mut bucket.bottle_table, debtor);
        bottle::record_withdraw(&mut bottle, collateral_amount);
        bottle::update_stake_and_total_stake(&mut bucket.bottle_table, &mut bottle);
        let coll = balance::split(&mut bucket.collateral_vault, collateral_amount);
        assert!(!is_in_recovery_mode(bucket, oracle, clock), EBottleIsNotHealthy);
        assert!(is_healthy_bottle(bucket, oracle, clock, &bottle), EBottleIsNotHealthy);
        events::emit_bottle_updated<T>(debtor, &bottle);
        if (is_interest_table_exists(bucket)) {
            let interest_table = dof::remove<vector<u8>, InterestTable>(&mut bucket.id, b"interest_table");
            bottle::insert_bottle(&mut bucket.bottle_table, &interest_table, debtor, bottle, insertion_place, clock);
            dof::add(&mut bucket.id, b"interest_table", interest_table);
        } else {
            bottle::insert(&mut bucket.bottle_table, debtor, bottle, insertion_place);
        };
        coll
    }

    public(friend) fun handle_repay<T>(
        bucket: &mut Bucket<T>,
        debtor: address,
        buck_input_amount: u64,
        min_bottle_size: u64,
        if_check_debt: bool,
        clock: &Clock,
    ): Balance<T> {
        // accrue interest
        if (is_interest_table_exists(bucket)) {
            accrue_interests_by_debtor(bucket, debtor, clock);
        };
        let (_, buck_amount) = apply_pending(bucket, debtor);
        assert!(buck_amount >= buck_input_amount, ERepayTooMuch);
        let bottle = bottle::borrow_bottle_mut(&mut bucket.bottle_table, debtor);
        let (is_fully_repaid, return_amount) = bottle::record_repay(bottle, buck_input_amount, min_bottle_size, if_check_debt);
        if (is_fully_repaid) {
            events::emit_bottle_destroyed<T>(debtor, bottle);
        } else {
            events::emit_bottle_updated<T>(debtor, bottle);
        };
        bottle::update_stake_and_total_stake_by_debtor(&mut bucket.bottle_table, debtor);
        if (is_fully_repaid) {
            bottle::destroy_bottle(&mut bucket.bottle_table, debtor);
        } else {
            if (is_interest_table_exists(bucket)) {
                let interest_table = dof::remove<vector<u8>, InterestTable>(&mut bucket.id, b"interest_table");
                bottle::re_insert_bottle(&mut bucket.bottle_table, &interest_table, debtor,clock);
                dof::add(&mut bucket.id, b"interest_table", interest_table);
            } else {
                bottle::re_insert(&mut bucket.bottle_table, debtor);
            };
        };
        bucket.minted_buck_amount = bucket.minted_buck_amount - buck_input_amount;
        balance::split(&mut bucket.collateral_vault, return_amount)
    }

    public(friend) fun handle_transfer<T>(
        bucket: &mut Bucket<T>,
        debtor: address,
        new_debtor: address,
        clock: &Clock,
    ) {
        if (is_interest_table_exists(bucket)) {
            accrue_interests_by_debtor(bucket, debtor, clock);
        };
        apply_pending(bucket, debtor);
        let insertion_place = *prev_debtor(bucket, debtor);
        let bottle = bottle::remove_bottle(&mut bucket.bottle_table, debtor);
        if (is_interest_table_exists(bucket)) {
            let interest_table = dof::remove<vector<u8>, InterestTable>(&mut bucket.id, b"interest_table");
            bottle::insert_bottle(&mut bucket.bottle_table, &interest_table, new_debtor, bottle, insertion_place, clock);
            dof::add(&mut bucket.id, b"interest_table", interest_table);
        } else {
            bottle::insert(&mut bucket.bottle_table, new_debtor, bottle, insertion_place);
        };
    }

    public(friend) fun handle_repay_capped<T>(
        bucket: &mut Bucket<T>,
        debtor: address,
        buck_input_amount: u64,
        oracle: &BucketOracle,
        clock: &Clock,
    ): Balance<T> {
        // accrue interest
        if (is_interest_table_exists(bucket)) {
            accrue_interests_by_debtor(bucket, debtor, clock);
        };
        let (_, buck_amount) = apply_pending(bucket, debtor);
        assert!(buck_amount >= buck_input_amount, ERepayTooMuch);
        let mcr = get_minimum_collateral_ratio(bucket);
        let bottle = bottle::borrow_bottle_mut(&mut bucket.bottle_table, debtor);
        let (is_fully_repaid, return_amount) = bottle::record_repay_capped<T>(bottle, buck_input_amount, oracle, clock, mcr, bucket.collateral_decimal);
        if (is_fully_repaid) events::emit_bottle_destroyed<T>(debtor, bottle);
        bottle::update_stake_and_total_stake_by_debtor(&mut bucket.bottle_table, debtor);
        let (bottle_coll_amount, _) = bottle::get_bottle_info_by_debtor(&bucket.bottle_table, debtor);
        if (is_fully_repaid) {
            if (bottle_coll_amount == 0) {
                bottle::destroy_bottle(&mut bucket.bottle_table, debtor);
            } else {
                let bottle = bottle::remove_bottle(&mut bucket.bottle_table, debtor);
                events::emit_surplus_bottle_generated<T>(debtor, &bottle);
                table::add(&mut bucket.surplus_bottle_table, debtor, bottle);
            }
        };
        bucket.minted_buck_amount = bucket.minted_buck_amount - buck_input_amount;
        balance::split(&mut bucket.collateral_vault, return_amount)
    }

    public(friend) fun handle_redeem<T>(
        bucket: &mut Bucket<T>,
        oracle: &BucketOracle,
        clock: &Clock,
        buck_input_amount: u64,
        insertion_place: Option<address>,
    ): Balance<T> {
        let (price, denominator) = bucket_oracle::get_price<T>(oracle, clock);
        let collateral_output = balance::zero();
        let remaining_redemption_amount = buck_input_amount;
        while(remaining_redemption_amount > 0 && bottle::get_table_length(&bucket.bottle_table) > 0) {
            let debtor = option::destroy_some(bottle::get_lowest_cr_debtor(&bucket.bottle_table));
            if (is_interest_table_exists(bucket)) {
                accrue_interests_by_debtor(bucket, debtor, clock);
            };
            let (_, bottle_buck_amount) = apply_pending(bucket, debtor);
            let (debtor, bottle) = bottle::pop_front(&mut bucket.bottle_table);
            if (remaining_redemption_amount >= bottle_buck_amount) {
                let redeemed_amount = compute_buck_value_to_collateral(bottle_buck_amount, bucket.collateral_decimal, price, denominator);
                bottle::record_redeem(&mut bottle, redeemed_amount, bottle_buck_amount);
                events::emit_bottle_destroyed<T>(debtor, &bottle);
                events::emit_surplus_bottle_generated<T>(debtor, &bottle);
                // update the debtor's stakes
                bottle::update_stake_and_total_stake(&mut bucket.bottle_table, &mut bottle);
                balance::join(&mut collateral_output, balance::split(&mut bucket.collateral_vault, redeemed_amount));
                table::add(&mut bucket.surplus_bottle_table, debtor, bottle);
                remaining_redemption_amount = remaining_redemption_amount - bottle_buck_amount;
            } else {
                let redeemed_amount = compute_buck_value_to_collateral(remaining_redemption_amount, bucket.collateral_decimal, price, denominator);
                bottle::record_redeem(&mut bottle, redeemed_amount, remaining_redemption_amount);
                events::emit_bottle_updated<T>(debtor, &bottle);
                balance::join(&mut collateral_output, balance::split(&mut bucket.collateral_vault, redeemed_amount));
                if (is_interest_table_exists(bucket)) {
                    let interest_table = dof::remove<vector<u8>, InterestTable>(&mut bucket.id, b"interest_table");
                    bottle::insert_bottle(&mut bucket.bottle_table, &interest_table, debtor, bottle, insertion_place, clock);
                    dof::add(&mut bucket.id, b"interest_table", interest_table);
                } else {
                    bottle::insert(&mut bucket.bottle_table, debtor, bottle, insertion_place);
                };
                remaining_redemption_amount = 0;
                // update the debtor's stakes
                bottle::update_stake_and_total_stake_by_debtor(&mut bucket.bottle_table, debtor);
                break
            };
        };
        assert!(remaining_redemption_amount == 0, ENotEnoughToRedeem);
        bucket.minted_buck_amount = bucket.minted_buck_amount - buck_input_amount;
        events::emit_redeem<T>(buck_input_amount, balance::value(&collateral_output));

        collateral_output
    }

    public fun bottle_exists<T>(bucket: &Bucket<T>, debtor: address): bool {
        bottle::bottle_exists(&bucket.bottle_table, debtor)
    }

    public fun get_bottle_info<T>(bucket: &Bucket<T>, bottle: &Bottle): (u64, u64) {
        bottle::get_bottle_info(&bucket.bottle_table, bottle)
    }

    public fun get_bottle_info_by_debtor<T>(bucket: &Bucket<T>, debtor: address): (u64, u64) {
        bottle::get_bottle_info_by_debtor(&bucket.bottle_table, debtor)
    }

    public fun get_bottle_info_with_interest<T>(bucket: &Bucket<T>, bottle: &Bottle, clock: &Clock): (u64, u64) {
        let bottle_table = borrow_bottle_table(bucket);
        if (dof::exists_with_type<vector<u8>, InterestTable>(&bucket.id, b"interest_table")) {
            let interest_table = borrow_interest_table(bucket);
            bottle::get_bottle_info_with_interest(bottle_table, bottle, interest_table, clock)
        } else {
            bottle::get_bottle_info(bottle_table, bottle)
        }
    }

    public fun get_bottle_info_with_interest_by_debtor<T>(bucket: &Bucket<T>, debtor: address, clock: &Clock): (u64, u64) {
        let bottle_table = borrow_bottle_table(bucket);
        if (dof::exists_with_type<vector<u8>, InterestTable>(&bucket.id, b"interest_table")) {
            let interest_table = borrow_interest_table(bucket);
            bottle::get_bottle_info_with_interest_by_debtor(bottle_table, debtor, interest_table, clock)
        } else {
            bottle::get_bottle_info_by_debtor(bottle_table, debtor)
        }
    }

    public fun get_surplus_bottle_info_by_debtor<T>(bucket: &Bucket<T>, debtor: address): (u64, u64) {
        let bottle = table::borrow(&bucket.surplus_bottle_table, debtor);
        bottle::get_bottle_raw_info(bottle)
    }

    public fun is_healthy_bottle<T>(bucket: &Bucket<T>, oracle: &BucketOracle, clock: &Clock, bottle: &Bottle): bool {
        let min_collateral_ratio = if (is_in_recovery_mode(bucket, oracle, clock)) {
            bucket.recovery_mode_threshold
        } else {
            bucket.min_collateral_ratio
        };
        let (price, denominator) = bucket_oracle::get_price<T>(oracle, clock);
        let (coll_amount, buck_amount) =
            if (is_interest_table_exists(bucket)) {
                get_bottle_info_with_interest(bucket, bottle, clock)
            } else {
                get_bottle_info(bucket, bottle)
            };
        compute_collateral_value_to_buck(coll_amount, bucket.collateral_decimal, price, denominator) >=
            mul_factor(buck_amount, min_collateral_ratio, 100)
    }

    public fun is_healthy_bottle_by_debtor<T>(bucket: &Bucket<T>, oracle: &BucketOracle, clock: &Clock, debtor: address): bool {
        let min_collateral_ratio = if (is_in_recovery_mode(bucket, oracle, clock)) {
            bucket.recovery_mode_threshold
        } else {
            bucket.min_collateral_ratio
        };
        let (price, denominator) = bucket_oracle::get_price<T>(oracle, clock);
        let (coll_amount, buck_amount) =
            if (is_interest_table_exists(bucket)) {
                get_bottle_info_with_interest_by_debtor(bucket, debtor, clock)
            } else {
                get_bottle_info_by_debtor(bucket, debtor)
            };
        compute_collateral_value_to_buck(coll_amount, bucket.collateral_decimal, price, denominator) >=
            mul_factor(buck_amount, min_collateral_ratio, 100)
    }

    // 12345 -> 123.45%
    public fun get_bucket_tcr<T>(bucket: &Bucket<T>, oracle: &BucketOracle, clock: &Clock): u64 {
        let collateral_amount = get_total_collateral_balance(bucket) + bucket.total_flash_loan_amount;
        let debt_amount = get_bucket_debt(bucket, clock);
        if (debt_amount == 0) return constants::max_u64();
        let (price, denominator) = bucket_oracle::get_price<T>(oracle, clock);
        let coll_value = compute_collateral_value_to_buck(collateral_amount, bucket.collateral_decimal, price, denominator);
        mul_factor(coll_value, 100_00, debt_amount)
    }

    // 12345 -> 123.45%
    public fun get_bottle_icr<T>(bucket: &Bucket<T>, oracle: &BucketOracle, clock: &Clock, debtor: address): u64 {
        let (price, denominator) = bucket_oracle::get_price<T>(oracle, clock);
        let (coll_amount, buck_amount) =
            if (is_interest_table_exists(bucket)) {
                get_bottle_info_with_interest_by_debtor(bucket, debtor, clock)
            } else {
                get_bottle_info_by_debtor(bucket, debtor)
            };
        let coll_value = compute_collateral_value_to_buck(coll_amount, bucket.collateral_decimal, price, denominator);
        let coll_ratio = if (buck_amount > 0) {
            mul_factor(coll_value, 100_00, buck_amount)
        } else { // denominator cannot be 0, represent infinity ICR when debt is 0
            constants::max_u64()
        };
        coll_ratio
    }

    public fun get_bottle_table_length<T>(bucket: &Bucket<T>): u64 {
        bottle::get_table_length(&bucket.bottle_table)
    }

    public fun get_collateral_vault_balance<T>(bucket: &Bucket<T>): u64 {
        balance::value(&bucket.collateral_vault)
    }

    public fun get_minted_buck_amount<T>(bucket: &Bucket<T>): u64 {
        bucket.minted_buck_amount
    }

    // bukcet.minted_buck_amount will not include some interest just added
    // use this function to get the real entire system debt
    public fun get_bucket_debt<T>(bucket: &Bucket<T>, clock: &Clock): u64 {
        let current_debt = bucket.minted_buck_amount;
        if (is_interest_table_exists(bucket)) {
            let interest_table = borrow_interest_table(bucket);
            let (_, interest_factor) = interest::calculate_interest_index(interest_table, clock);
            if (interest_factor > 0) {
                let active_interests = mul_factor_u256(
                    (current_debt as u256),
                    interest_factor,
                    constants::interest_precision()
                );
                assert!(active_interests <= (constants::max_u64() as u256), EOverflow);
                current_debt = current_debt + (active_interests as u64);
            };
        };

        current_debt
    }

    public fun get_bucket_size<T>(bucket: &Bucket<T>): u64 {
        bottle::get_table_length(&bucket.bottle_table)
    }

    public fun get_lowest_cr_debtor<T>(bucket: &Bucket<T>): Option<address> {
        bottle::get_lowest_cr_debtor(&bucket.bottle_table)
    }

    public fun is_liquidatable<T>(
        bucket: &Bucket<T>,
        oracle: &BucketOracle,
        clock: &Clock,
        debtor: address,
    ): bool {
        !is_healthy_bottle_by_debtor(bucket, oracle, clock, debtor)
    }

    public fun has_liquidatable_bottle<T>(
        bucket: &Bucket<T>,
        oracle: &BucketOracle,
        clock: &Clock,
    ): bool {
        let debtor = get_lowest_cr_debtor(bucket);
        if (option::is_none(&debtor)) {
            option::destroy_none(debtor);
            return false
        };
        let debtor = option::destroy_some(debtor);
        is_liquidatable<T>(bucket, oracle, clock, debtor)
    }

    public fun is_in_recovery_mode<T>(bucket: &Bucket<T>, oracle: &BucketOracle, clock: &Clock): bool {
        let (price, denominator) = bucket_oracle::get_price<T>(oracle, clock);
        let bucket_total_collateral_amount = get_total_collateral_balance(bucket) + bucket.total_flash_loan_amount;
        let bucket_total_debt_amount = get_bucket_debt(bucket, clock);
        compute_collateral_value_to_buck(bucket_total_collateral_amount, bucket.collateral_decimal, price, denominator) <=
            mul_factor(bucket_total_debt_amount, bucket.recovery_mode_threshold, 100)
    }

    public fun is_interest_table_exists<T>(bucket: &Bucket<T>): bool {
        dof::exists_<vector<u8>>(&bucket.id, b"interest_table")
    }

    public(friend) fun handle_flash_borrow<T>(
        bucket: &mut Bucket<T>,
        amount: u64,
    ): (Balance<T>, FlashReceipt<T>) {
        bucket.total_flash_loan_amount = bucket.total_flash_loan_amount + amount;
        let fee = mul_factor(amount, constants::flash_loan_fee(), constants::fee_precision());
        if (fee == 0) fee = 1;
        (balance::split(&mut bucket.collateral_vault, amount), FlashReceipt { amount, fee })
    }

    public(friend) fun handle_flash_repay<T>(
        bucket: &mut Bucket<T>,
        repayment: Balance<T>,
        receipt: FlashReceipt<T>,
    ): Balance<T> {
        let FlashReceipt { amount, fee } = receipt;
        bucket.total_flash_loan_amount = bucket.total_flash_loan_amount - amount;
        assert!(balance::value(&repayment) >= amount + fee, EFlashFeeNotEnough);
        let repayment_to_vault = balance::split(&mut repayment, amount);
        balance::join(&mut bucket.collateral_vault, repayment_to_vault);
        repayment
    }

    public fun is_not_locked<T>(bucket: &Bucket<T>): bool {
         bucket.total_flash_loan_amount == 0
    }

    public fun get_total_flash_loan_amount<T>(bucket: &Bucket<T>): u64 {
        bucket.total_flash_loan_amount
    }

    public fun get_receipt_info<T>(receipt: &FlashReceipt<T>): (u64, u64) {
        (receipt.amount, receipt.fee)
    }

    public fun get_minimum_collateral_ratio<T>(bucket: &Bucket<T>): u64 {
        bucket.min_collateral_ratio
    }

    public fun get_max_mint_amount<T>(bucket: &Bucket<T>): Option<u64> {
        bucket.max_mint_amount
    }

    public fun compute_base_rate<T>(bucket: &Bucket<T>, current_time: u64): u64 {
        let minutes = (current_time - bucket.latest_redemption_time) / 60000;
        if (minutes > 525600000) minutes = 525600000;
        if (minutes == 0) return bucket.base_fee_rate;

        let y = constants::decay_factor_precision();
        let x = constants::minute_decay_factor();
        let n = minutes;

        while (n > 1) {
            if (n % 2 == 0) {
                x = mul_factor(x, x, constants::decay_factor_precision());
                n = n >> 1;
            } else {
                y = mul_factor(x ,y, constants::decay_factor_precision());
                x = mul_factor(x, x, constants::decay_factor_precision());
                n = (n - 1) / 2;
            };
        };

        let decay_factor = mul_factor(x, y, constants::decay_factor_precision());
        mul_factor(
            bucket.base_fee_rate,
            decay_factor,
            constants::decay_factor_precision()
        )
    }

    fun compute_collateral_value_to_buck(
        collateral_amount: u64,
        collateral_decimal: u8,
        price: u64,
        denominator: u64
    ): u64 {
        let collateral_raw_value = mul_factor(collateral_amount, price, denominator);
        if (constants::buck_decimal() >= collateral_decimal) {
            collateral_raw_value * pow(10, constants::buck_decimal() - collateral_decimal)
        } else {
            collateral_raw_value / pow(10, collateral_decimal - constants::buck_decimal())
        }
    }

    fun compute_buck_value_to_collateral(buck_amount: u64, collateral_decimal: u8, price: u64, denominator: u64, ): u64 {
        let buck_raw_value = mul_factor(buck_amount, denominator, price);
        if (constants::buck_decimal() >= collateral_decimal) {
            buck_raw_value / pow(10, constants::buck_decimal() - collateral_decimal)
        } else {
            buck_raw_value * pow(10, collateral_decimal - constants::buck_decimal())
        }
    }

    public(friend) fun update_base_rate_fee<T>(
        bucket: &mut Bucket<T>,
        base_fee_rate: u64,
        latest_redemption_time: u64
    ) {
        bucket.base_fee_rate = base_fee_rate;
        bucket.latest_redemption_time = latest_redemption_time;
        events::emit_fee_rate_changed<T>(base_fee_rate);
    }

    public(friend) fun update_snapshot<T>(bucket: &mut Bucket<T>) {
        let collateral_value = get_total_collateral_balance(bucket);
        bottle::update_snapshot(
            &mut bucket.bottle_table,
            collateral_value,
        );
    }

    public(friend) fun withdraw_surplus_collateral<T>(
        bucket: &mut Bucket<T>,
        debtor: address,
    ): Balance<T> {
        assert!(table::contains(&bucket.surplus_bottle_table, debtor),
            ESurplusBottleNotFound,
        );

        let bottle =
            table::remove(
                &mut bucket.surplus_bottle_table,
                debtor
            );

        events::emit_surplus_bottle_withdrawal<T>(debtor, &bottle);

        let collateral_amount = bottle::destroy_surplus_bottle(bottle);
        balance::split(&mut bucket.collateral_vault, collateral_amount)
    }

    public(friend) fun update_max_mint_amount<T>(bucket: &mut Bucket<T>, max_mint_amount: Option<u64>) {
        bucket.max_mint_amount = max_mint_amount;
    }

    public(friend) fun update_liquidation_config<T>(
        bucket: &mut Bucket<T>,
        min_collateral_ratio: u64,
        recovery_mode_threshold: u64
    ) {
        bucket.min_collateral_ratio = min_collateral_ratio;
        bucket.recovery_mode_threshold = recovery_mode_threshold;
    }

    public fun get_surplus_collateral_amount<T>(bucket: &Bucket<T>, debtor: address): u64 {
        let (collateral_amount, _) = bottle::get_bottle_raw_info(
            table::borrow(&bucket.surplus_bottle_table, debtor)
        );
        collateral_amount
    }

    public fun get_surplus_bottle_table_size<T>(bucket: &Bucket<T>): u64 {
        table::length(borrow_surplus_bottle_table(bucket))
    }

    public fun borrow_bottle_table<T>(bucket: &Bucket<T>): &BottleTable {
        &bucket.bottle_table
    }

    public fun borrow_surplus_bottle_table<T>(bucket: &Bucket<T>): &Table<address, Bottle> {
        &bucket.surplus_bottle_table
    }

    public fun borrow_pending_record<T>(bucket: &Bucket<T>): &PendingRecord {
        dof::borrow<vector<u8>, PendingRecord>(&bucket.id, b"pending_record")
    }

    public(friend) fun borrow_pending_record_mut<T>(bucket: &mut Bucket<T>): &mut PendingRecord {
        dof::borrow_mut<vector<u8>, PendingRecord>(&mut bucket.id, b"pending_record")
    }

    public fun get_bucket_pending_debt<T>(bucket: &Bucket<T>): u64 {
        borrow_pending_record(bucket).bucket_pending_debt
    }

    public fun get_bucket_pending_collateral<T>(bucket: &Bucket<T>): u64 {
        borrow_pending_record(bucket).bucket_pending_collateral
    }

    public fun prev_debtor<T>(bucket: &Bucket<T>, debtor: address): &Option<address> {
        let table = bottle::borrow_table(&bucket.bottle_table);
        linked_table::prev(table, debtor)
    }

    public fun next_debtor<T>(bucket: &Bucket<T>, debtor: address): &Option<address> {
        let table = bottle::borrow_table(&bucket.bottle_table);
        linked_table::next(table, debtor)
    }

    fun apply_pending<T>(bucket: &mut Bucket<T>, debtor: address): (u64, u64) {
        // update pending record
        if (dof::exists_with_type<vector<u8>, PendingRecord>(&bucket.id, b"pending_record")) {
            let table = borrow_bottle_table(bucket);
            let bottle = bottle::borrow_bottle(table, debtor);
            let pending_coll = bottle::get_pending_coll(bottle, table);
            let pending_debt = bottle::get_pending_debt(bottle, table);
            let pending_record = borrow_pending_record_mut(bucket);
            pending_record.bucket_pending_collateral = pending_record.bucket_pending_collateral - pending_coll;
            pending_record.bucket_pending_debt = pending_record.bucket_pending_debt - pending_debt;
        };

        bottle::get_bottle_info_after_update(&mut bucket.bottle_table, debtor)
    }

    public(friend) fun adjust_pending_record<T>(
        bucket: &mut Bucket<T>,
        total_pending_coll: u64,
        total_pending_debt: u64,
    ) {
        let pending_record = borrow_pending_record_mut(bucket);
        pending_record.bucket_pending_collateral = total_pending_coll;
        pending_record.bucket_pending_debt = total_pending_debt;
    }

    // ======== bottle strap

    use bucket_protocol::strap::{Self, BottleStrap};

    public fun destroy_empty_strap<T>(
        bucket: &Bucket<T>,
        strap: BottleStrap<T>,
    ) {
        let strap_addr = strap::get_address(&strap);
        assert!(
            !bottle_exists(bucket, strap_addr) &&
            !table::contains(&bucket.surplus_bottle_table, strap_addr),
            ECannotDestroyNonEmptyStrap,
        );
        strap::destroy(strap);
    }

    // ======== bottle strap

    // ======== pipe

    use sui::dynamic_field as df;

    struct OutputKey has store, copy, drop {}

    struct OutputVolume has store {
        volume: u64,
    }

    public(friend) fun output<T>(
        bucket: &mut Bucket<T>,
        volume: u64,
    ): Balance<T> {
        let key = OutputKey {};
        if (!df::exists_with_type<OutputKey, OutputVolume>(&bucket.id, key)) {
            df::add(&mut bucket.id, key, OutputVolume { volume: 0 });
        };
        let volume_mut = df::borrow_mut<OutputKey, OutputVolume>(&mut bucket.id, key);
        volume_mut.volume = volume_mut.volume + volume;
        balance::split(&mut bucket.collateral_vault, volume)
    }

    public(friend) fun input<T>(
        bucket: &mut Bucket<T>,
        content: Balance<T>,
    ) {
        let key = OutputKey {};
        let volume_mut = df::borrow_mut<OutputKey, OutputVolume>(&mut bucket.id, key);
        let volume = balance::value(&content);
        volume_mut.volume = volume_mut.volume - volume;
        balance::join(&mut bucket.collateral_vault, content);
    }

    public fun get_collateral_output_volume<T>(bucket: &Bucket<T>): u64 {
        let key = OutputKey {};
        if (df::exists_with_type<OutputKey, OutputVolume>(&bucket.id, key)) {
            let volume = df::borrow<OutputKey, OutputVolume>(&bucket.id, key);
            volume.volume
        } else {
            0
        }
    }

    public fun get_total_collateral_balance<T>(bucket: &Bucket<T>): u64 {
        let vault_value = get_collateral_vault_balance(bucket);
        let output_value = get_collateral_output_volume(bucket);
        vault_value + output_value
    }

    // ======== pipe

    // ======== surplus

    public(friend) fun handle_deposit_surplus<T>(
        bucket: &mut Bucket<T>,
        account: address,
        collateral: Balance<T>,
        ctx: &mut TxContext,
    ) {
        let coll_value = balance::value(&collateral);
        let surplus_table = &mut bucket.surplus_bottle_table;
        if (table::contains(surplus_table, account)) {
            let bottle_mut = table::borrow_mut(surplus_table, account);
            bottle::record_top_up(bottle_mut, coll_value);
        } else {
            let bottle = bottle::new_surplus_bottle(coll_value, ctx);
            table::add(surplus_table, account, bottle);
        };
        balance::join(&mut bucket.collateral_vault, collateral);
    }

    // ======== surplus

    #[test_only]
    use sui::sui::SUI;

    #[test_only]
    public fun check_bottle_order_in_bucket<T>(bucket: &Bucket<T>, if_print: bool): u64 {
        bottle::check_bottle_order_in_bucket(&bucket.bottle_table, if_print)
    }

    fun check_insertion_place<T>(
        bucket: &Bucket<T>,
        debtor: address,
        insertion_place: &mut Option<address>,
    ) {
        if(
            option::is_some(insertion_place) &&
            *option::borrow(insertion_place) == debtor
        ) {
            let table = bottle::borrow_table(&bucket.bottle_table);
            let prev_debtor = *linked_table::prev(table, debtor);
            if (option::is_none(&prev_debtor)) {
                option::extract(insertion_place);
            } else {
                option::swap(insertion_place, option::destroy_some(prev_debtor));
            };
        };
    }

    #[test]
    fun test_compute_base_rate(): Bucket<SUI> {
        use sui::test_scenario;

        let dev = @0xde1;

        let scenario_val = test_scenario::begin(dev);
        let scenario = &mut scenario_val;

        let bucket = new<SUI>(110, 150, 9, option::none(), test_scenario::ctx(scenario));
        bucket.base_fee_rate = 50000;
        // std::debug::print(&bucket);
        // std::debug::print(&compute_base_rate(&bucket, 43200000 * 3));
        test_scenario::end(scenario_val);

        bucket
    }
}
