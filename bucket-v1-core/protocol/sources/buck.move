module bucket_protocol::buck {

    // Dependecies

    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::table;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use sui::url;
    use sui::clock::{Self, Clock};
    use sui::dynamic_object_field as dof;
    use std::option::{Self, Option};

    use bucket_framework::math::mul_factor;
    use bucket_protocol::math::mul_factor_u256;
    use bucket_protocol::well::{Self, Well};
    use bucket_protocol::bucket::{Self, Bucket, FlashReceipt as BucketFlashReceipt};
    use bucket_protocol::tank::{Self, Tank, FlashReceipt as TankFlashReceipt, ContributorToken};
    use bucket_protocol::bkt::{Self, BktTreasury, BKT};
    use bucket_protocol::reservoir::{Self, Reservoir};
    use bucket_oracle::bucket_oracle::{Self as bo, BucketOracle};
    use bucket_protocol::constants;
    use bucket_protocol::buck_events;
    use bucket_protocol::well_events;
    use bucket_protocol::interest;

    use flask::sbuck::{Self, SBUCK, Flask};

    const PACKAGE_VERSION: u64 = 7;

    // Errors
    const ENotLiquidatable: u64 = 1;
    const EBucketAlreadyExists: u64 = 2;
    const ETankLocked: u64 = 4;
    const ENotSupportedType: u64 = 5;
    const ENotRecoveryMode: u64 = 6;
    const ENotNormalMode: u64 = 7;
    const EHasLiquidataleBottle: u64 = 8;
    const ETankEmptyInRecoveryMode: u64 = 9;
    const ENotInSurplus: u64 = 10;
    const EInvalidFlashMintAmount: u64 = 11;
    const EFlashBurnNotEnought: u64 = 12;
    const EFlashMintConfigIdNotMatched: u64 = 13;
    const EBucketLocked: u64 = 14;
    const EInterestIndexShouldLargeThanCurrent: u64 = 15;
    const EInvalidInterestRate: u64 = 16;
    const ECannotUseNormalPipeForBuck: u64 = 17;
    const ECannotChangeLiquidationConfig: u64 = 18;
    const EInvalidPackageVersion: u64 = 99;
    const EDeprecated: u64 = 404;

    // Types

    struct BUCK has drop {}

    struct BucketProtocol has key {
        id: UID,
        version: u64,
        buck_treasury_cap: TreasuryCap<BUCK>,
        min_bottle_size: u64,
    }

    struct BucketType<phantom T> has copy, drop, store {}

    struct WellType<phantom T> has copy, drop, store {}

    struct TankType<phantom T> has copy, drop, store {}

    struct AdminCap has key, store { id: UID } // Admin can create new bucket

    // Init

    #[lint_allow(share_owned)]
    fun init(witness: BUCK, ctx: &mut TxContext) {     
        let (protocol, admin_cap) = new_protocol(witness, ctx);

        transfer::share_object(protocol);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    fun new_protocol(witness: BUCK, ctx: &mut TxContext): (BucketProtocol, AdminCap) {
        let (buck_treasury_cap, buck_metadata) = coin::create_currency(
            witness,
            constants::buck_decimal(),
            b"BUCK",
            b"Bucket USD",
            b"the stablecoin minted through bucketprotocol.io",
            option::some(url::new_unsafe_from_bytes(
                b"https://ipfs.io/ipfs/QmYH4seo7K9CiFqHGDmhbZmzewHEapAhN9aqLRA7af2vMW"),
            ),
            ctx,
        );

        transfer::public_freeze_object(buck_metadata);
        let id = object::new(ctx);

        // create well for BUCK
        dof::add(&mut id, WellType<BUCK> {}, well::new<BUCK>(ctx));

        let protocol = BucketProtocol {
            id,
            version: PACKAGE_VERSION,
            buck_treasury_cap,
            min_bottle_size: 10_000_000_000,
        };
        let admin_cap = AdminCap { id: object::new(ctx) };

        create_bucket<SUI>(&admin_cap, &mut protocol, 110, 150, 9, option::none(), ctx);
        // create_bucket<WBTC>(&admin_cap, &mut protocol, 110, 150, 8, option::none(), ctx);
        // create_bucket<WETH>(&admin_cap, &mut protocol, 110, 150, 8, option::none(), ctx);
        // create_bucket<USDT>(&admin_cap, &mut protocol, 105, 110, 6, option::none(), ctx);
        // create_bucket<USDC>(&admin_cap, &mut protocol, 105, 110, 6, option::none(), ctx);
        
        (protocol, admin_cap)
    } 

    #[test_only]
    fun new_protocol_with_interest(witness: BUCK, clock: &Clock, ctx: &mut TxContext): (BucketProtocol, AdminCap) {
        let (buck_treasury_cap, buck_metadata) = coin::create_currency(
            witness,
            constants::buck_decimal(),
            b"BUCK",
            b"Bucket USD",
            b"the stablecoin minted through bucketprotocol.io",
            option::some(url::new_unsafe_from_bytes(
                b"https://ipfs.io/ipfs/QmYH4seo7K9CiFqHGDmhbZmzewHEapAhN9aqLRA7af2vMW"),
            ),
            ctx,
        );

        transfer::public_freeze_object(buck_metadata);
        let id = object::new(ctx);

        // create well for BUCK
        dof::add(&mut id, WellType<BUCK> {}, well::new<BUCK>(ctx));

        let protocol = BucketProtocol {
            id,
            version: PACKAGE_VERSION,
            buck_treasury_cap,
            min_bottle_size: 10_000_000_000,
        };
        let admin_cap = AdminCap { id: object::new(ctx) };

        create_bucket_with_interest_table<SUI>(&admin_cap, &mut protocol, 110, 150, 9, option::none(), clock, 0, ctx);
        // create_bucket<WBTC>(&admin_cap, &mut protocol, 110, 150, 8, option::none(), ctx);
        // create_bucket<WETH>(&admin_cap, &mut protocol, 110, 150, 8, option::none(), ctx);
        // create_bucket<USDT>(&admin_cap, &mut protocol, 105, 110, 6, option::none(), ctx);
        // create_bucket<USDC>(&admin_cap, &mut protocol, 105, 110, 6, option::none(), ctx);
        
        (protocol, admin_cap)
    } 

    // Functions

    public fun borrow<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        collateral_input: Balance<T>,
        buck_output_amount: u64,
        insertion_place: Option<address>,
        ctx: &mut TxContext,
    ): Balance<BUCK> {
        assert_valid_package_version(protocol);
        // handle collateral
        let min_bottle_size = protocol.min_bottle_size;
        let bucket = borrow_bucket_mut<T>(protocol);
        let fee_rate = compute_base_rate_fee<T>(bucket, clock);
        let fee_amount = mul_factor(
            buck_output_amount, 
            fee_rate, 
            constants::fee_precision()
        );
        buck_events::emit_collateral_increased<T>(balance::value(&collateral_input));
        let borrower = tx_context::sender(ctx);
        bucket::handle_borrow(bucket, oracle, borrower, clock, collateral_input, buck_output_amount + fee_amount, insertion_place, min_bottle_size, ctx);
        // mint BUCK and charge borrow fee
        let fee = mint_buck<T>(protocol, fee_amount);
        well_events::emit_collect_fee_from(&fee, b"borrow");
        well::collect_fee(borrow_well_mut<BUCK>(protocol), fee);
        mint_buck<T>(protocol, buck_output_amount)
    }

    // deprecated
    public fun top_up<T>(
        _protocol: &mut BucketProtocol,
        _collateral_input: Balance<T>,
        _for: address,
        _insertion_place: Option<address>,
    ) {
        abort EDeprecated
    }

    public fun top_up_coll<T>(
        protocol: &mut BucketProtocol,
        collateral_input: Balance<T>,
        for: address,
        insertion_place: Option<address>,
        clock: &Clock,
    ) {
        assert_valid_package_version(protocol);
        // handle collateral
        let bucket = borrow_bucket_mut<T>(protocol);
        buck_events::emit_collateral_increased<T>(balance::value(&collateral_input));
        bucket::handle_top_up(bucket, collateral_input, for, insertion_place, clock);
    }

    public fun withdraw<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        collateral_amount: u64,
        insertion_place: Option<address>,
        ctx: &TxContext,
    ): Balance<T> {
        let bucket = borrow_bucket_mut<T>(protocol);
        assert!(bucket::is_not_locked(bucket), EBucketLocked);   
        buck_events::emit_collateral_decreased<T>(collateral_amount);
        let debtor = tx_context::sender(ctx);
        bucket::handle_withdraw(bucket, oracle, debtor, clock, collateral_amount, insertion_place)
    }

    // deprecated
    public fun repay<T>(
        _protocol: &mut BucketProtocol,
        _buck_input: Balance<BUCK>,
        _ctx: &TxContext,
    ): Balance<T> {
        abort EDeprecated
    }
    
    public fun repay_debt<T>(
        protocol: &mut BucketProtocol,
        buck_input: Balance<BUCK>,
        clock: &Clock,
        ctx: &TxContext,
    ): Balance<T> {
        assert_valid_package_version(protocol);
        let min_bottle_size = protocol.min_bottle_size;
        let debtor = tx_context::sender(ctx);
        let buck_input_amount = balance::value(&buck_input);

        // burn BUCK
        burn_buck<T>(protocol, buck_input);
        // return collateral
        let bucket = borrow_bucket_mut<T>(protocol);
        assert!(bucket::is_not_locked(bucket), EBucketLocked);
        let collateral_output = bucket::handle_repay<T>(bucket, debtor, buck_input_amount, min_bottle_size, true, clock);
        buck_events::emit_collateral_decreased<T>(balance::value(&collateral_output));
        collateral_output
    }

    public fun redeem<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        buck_input: Balance<BUCK>,
        insertion_place: Option<address>,
    ): Balance<T> {
        assert_valid_package_version(protocol);
        let buck_input_amount = balance::value(&buck_input);

        // return Redemption
        let bucket = borrow_bucket_mut<T>(protocol);
        assert!(bucket::is_not_locked(bucket), EBucketLocked);
        let buck_minted = bucket::get_minted_buck_amount(bucket);
        let collateral_output = 
            bucket::handle_redeem<T>(
                bucket, 
                oracle, 
                clock, 
                buck_input_amount, 
                insertion_place
            );
        let collateral_output_amount = balance::value(&collateral_output);
        let fee_rate = 
            compute_base_rate_fee(bucket, clock) + 
            mul_factor(
                constants::fee_precision(), 
                buck_input_amount, 
                buck_minted
            ) / 2;
        let fee_amount = mul_factor(
            collateral_output_amount, 
            fee_rate, 
            constants::fee_precision()
        );
        bucket::update_base_rate_fee(bucket, fee_rate, clock::timestamp_ms(clock));
        let fee = balance::split(&mut collateral_output, fee_amount);
        well_events::emit_collect_fee_from(&fee, b"redeem");
        well::collect_fee(borrow_well_mut<T>(protocol), fee);
        buck_events::emit_collateral_decreased<T>(balance::value(&collateral_output));
        // burn BUCK
        burn_buck<T>(protocol, buck_input);
        collateral_output
    }

    public fun is_liquidatable<T>(
        protocol: &BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        debtor: address
    ): bool {
        let bucket = borrow_bucket<T>(protocol);
        bucket::is_liquidatable<T>(bucket, oracle, clock, debtor)
    }

    public fun liquidate_under_normal_mode<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        debtor: address,
    ): Balance<T> {
        assert_valid_package_version(protocol);
        let bucket = borrow_bucket<T>(protocol);
        assert!(!bucket::is_in_recovery_mode(bucket, oracle, clock), ENotNormalMode);
        assert!(bucket::is_not_locked(bucket), EBucketLocked);

        normally_liquidate(protocol, oracle, clock, debtor, option::none())
    }

    public fun liquidate_under_recovery_mode<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        debtor: address,
    ): Balance<T> {
        assert_valid_package_version(protocol);
        assert!(is_liquidatable<T>(protocol, oracle, clock, debtor), ENotLiquidatable);
        assert!(tank::is_not_locked(borrow_tank<T>(protocol)), ETankLocked);
        
        let tank_reserve = tank::get_reserve_balance(borrow_tank<T>(protocol));
        let bucket = borrow_bucket_mut<T>(protocol);
        assert!(bucket::is_in_recovery_mode(bucket, oracle, clock), ENotRecoveryMode);
        assert!(bucket::is_not_locked(bucket), EBucketLocked);
        
        let (_, buck_amount) = 
            if (bucket::is_interest_table_exists(bucket)) {
                // accrue interest
                bucket::accrue_interests_by_debtor(bucket, debtor, clock);
                bucket::get_bottle_info_with_interest_by_debtor(bucket, debtor, clock)
            } else {
                bucket::get_bottle_info_by_debtor(bucket, debtor)
            };
        let icr = bucket::get_bottle_icr(bucket, oracle, clock, debtor);
        let tcr = bucket::get_bucket_tcr(bucket, oracle, clock);
        let mcr = bucket::get_minimum_collateral_ratio<T>(bucket) * 100;
        
        // If icr <= 100%, purely redistribute
        let (fee, rebate) = if (icr < mcr) {

            let rebate = normally_liquidate(protocol, oracle, clock, debtor, option::some(tcr));
            (balance::zero(), rebate)
        
        // If 110% <= icr < TCR, with buck in tank, only offset, no redistribution.
        // If the whole debt can be liquidated: capped rate = 110%, the surplus can be claimed by the debtor.
        } else if (icr >= mcr && icr < tcr) {
            assert!(tank_reserve > 0, ETankEmptyInRecoveryMode);
            // absorb debt
            let buck_amount_to_repay = if (buck_amount <= tank_reserve) {
                buck_amount
            } else {
                tank_reserve
            };
            let bucket = borrow_bucket_mut<T>(protocol);
            let collateral_return = bucket::handle_repay_capped<T>(
                bucket, 
                debtor, 
                buck_amount_to_repay, 
                oracle, 
                clock
            );
            let coll_amount = balance::value(&collateral_return);

            // aborb all the debt, debt = 0, add to the surplus bottle table
            if (buck_amount == buck_amount_to_repay) {
                let bucket = borrow_bucket<T>(protocol);
                assert!(table::contains(bucket::borrow_surplus_bottle_table(bucket), debtor), ENotInSurplus);
            };
            
            let rebate_amount = mul_factor(
                balance::value(&collateral_return), 
                constants::liquidation_rebate(), 
                constants::fee_precision()
            );
            let fee_amount = mul_factor(
                balance::value(&collateral_return), 
                constants::liquidation_fee(), 
                constants::fee_precision()
            );
            let rebate = balance::split(&mut collateral_return, rebate_amount);
            let fee = balance::split(&mut collateral_return, fee_amount);
            
            let buck_to_burn = 
                tank::absorb(
                    borrow_tank_mut<T>(protocol), 
                    collateral_return, 
                    buck_amount_to_repay
                );

            // burn BUCK
            burn_buck<T>(protocol, buck_to_burn);
            
            // update bucket snapshot
            bucket::update_snapshot(borrow_bucket_mut<T>(protocol));

            // emit liquidation event
            buck_events::emit_collateral_decreased<T>(coll_amount);
            let (price_n, price_m) = bo::get_price<T>(oracle, clock);
            buck_events::emit_liquidation<T>(
                price_n,
                price_m,
                coll_amount,
                buck_amount_to_repay,
                option::some(tcr),
                debtor,
            );

            (fee, rebate)
        
        // If icr >= tcr and icr >= mcr, no liquidation
        } else {
            abort ENotLiquidatable
        };
        well_events::emit_collect_fee_from(&fee, b"liquidate");
        well::collect_fee(borrow_well_mut<T>(protocol), fee);        

        // return rebate
        rebate
    }

    fun normally_liquidate<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        debtor: address,
        tcr: Option<u64>,
    ): Balance<T> {
        assert_valid_package_version(protocol);
        let min_bottle_size = protocol.min_bottle_size;
        assert!(is_liquidatable<T>(protocol, oracle, clock, debtor), ENotLiquidatable);
        assert!(tank::is_not_locked(borrow_tank<T>(protocol)), ETankLocked);
        let tank_reserve = tank::get_reserve_balance(borrow_tank<T>(protocol));

        let bucket = borrow_bucket_mut<T>(protocol);
        let (_, buck_amount) = 
            if (bucket::is_interest_table_exists(bucket)) {
                // accrue interest
                bucket::accrue_interests_by_debtor(bucket, debtor, clock);
                bucket::get_bottle_info_with_interest_by_debtor(bucket, debtor, clock)
            } else {
                bucket::get_bottle_info_by_debtor(bucket, debtor)
            };
        let buck_amount_to_repay = if (buck_amount <= tank_reserve) {
            buck_amount
        } else {
            tank_reserve
        };

        let rebate = balance::zero();
        let fee = balance::zero();
        let collateral_return = 
            bucket::handle_repay<T>(bucket, debtor, buck_amount_to_repay, min_bottle_size, false, clock);
        let coll_amount = balance::value(&collateral_return);

        buck_events::emit_collateral_decreased<T>(balance::value(&collateral_return));
        
        let rebate_amount = mul_factor(
            balance::value(&collateral_return), 
            constants::liquidation_rebate(), 
            constants::fee_precision()
        );
        let fee_amount = mul_factor(
            balance::value(&collateral_return), 
            constants::liquidation_fee(), 
            constants::fee_precision()
        );
        balance::join(&mut rebate, balance::split(&mut collateral_return, rebate_amount));
        balance::join(&mut fee, balance::split(&mut collateral_return, fee_amount));

        // absorb debt
        let buck_to_burn = 
            tank::absorb(
                borrow_tank_mut<T>(protocol), 
                collateral_return, 
                buck_amount_to_repay
            );
        // burn BUCK
        burn_buck<T>(protocol, buck_to_burn);

        // update bucket snapshot
        let bucket = borrow_bucket_mut<T>(protocol);
        bucket::update_snapshot(bucket);
        well_events::emit_collect_fee_from(&fee, b"liquidate");
        well::collect_fee(borrow_well_mut(protocol), fee);

        // emit liquidation event
        let (price_n, price_m) = bo::get_price<T>(oracle, clock);
        buck_events::emit_liquidation<T>(
            price_n,
            price_m,
            coll_amount,
            buck_amount_to_repay,
            tcr,
            debtor,
        );

        // return rebate
        rebate
    }

    public fun flash_borrow<T>(
        protocol: &mut BucketProtocol,
        amount: u64,
    ): (Balance<T>, BucketFlashReceipt<T>) {
        assert_valid_package_version(protocol);
        let bucket = borrow_bucket_mut<T>(protocol);
        buck_events::emit_flash_loan<T>(amount);
        bucket::handle_flash_borrow(bucket, amount)
    }

    public fun flash_repay<T>(
        protocol: &mut BucketProtocol,
        repayment: Balance<T>,
        recepit: BucketFlashReceipt<T>,
    ) {
        assert_valid_package_version(protocol);
        let bucket = borrow_bucket_mut<T>(protocol);
        let fee = bucket::handle_flash_repay(bucket, repayment, recepit);

        let well = borrow_well_mut<T>(protocol);
        well_events::emit_collect_fee_from(&fee, b"flashloan");
        well::collect_fee(well, fee);
    }

    public fun flash_borrow_buck<T>(
        protocol: &mut BucketProtocol,
        amount: u64,
    ): (Balance<BUCK>, TankFlashReceipt<BUCK, T>) {
        assert_valid_package_version(protocol);
        let tank = borrow_tank_mut<T>(protocol);
        buck_events::emit_flash_loan<BUCK>(amount);
        tank::handle_flash_borrow(tank, amount)
    }

    public fun flash_repay_buck<T>(
        protocol: &mut BucketProtocol,
        repayment: Balance<BUCK>,
        recepit: TankFlashReceipt<BUCK, T>,
    ) {
        assert_valid_package_version(protocol);
        let tank = borrow_tank_mut<T>(protocol);
        let fee = tank::handle_flash_repay(tank, repayment, recepit);

        let well = borrow_well_mut<BUCK>(protocol);
        well_events::emit_collect_fee_from(&fee, b"flashloan");
        well::collect_fee(well, fee);
    }

    public fun tank_withdraw<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        bkt_treasury: &mut BktTreasury,
        token: ContributorToken<BUCK, T>,
        ctx: &TxContext,
    ): (Balance<BUCK>, Balance<T>, Balance<BKT>) {
        assert_valid_package_version(protocol);
        let bucket = borrow_bucket<T>(protocol);
        assert!(!bucket::has_liquidatable_bottle<T>(bucket, oracle, clock), EHasLiquidataleBottle);
        let tank = borrow_tank_mut<T>(protocol);
        tank::withdraw<BUCK, T>(tank, bkt_treasury, token, ctx)
    }

    public fun get_bottle_info_by_debtor<T>(protocol: &BucketProtocol, debtor: address): (u64, u64) {
        let bucket = borrow_bucket<T>(protocol);
        bucket::get_bottle_info_by_debtor(bucket, debtor)
    }

    public fun get_bottle_info_with_interest_by_debtor<T>(
        protocol: &BucketProtocol,
        debtor: address,
        clock: &Clock,
    ): (u64, u64) {
        let bucket = borrow_bucket<T>(protocol);
        bucket::get_bottle_info_with_interest_by_debtor(bucket, debtor, clock)
    }

    public entry fun create_bucket<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        min_collateral_ratio: u64,
        recovery_mode_threshold: u64,
        collateral_decimal: u8,
        max_mint_amount: Option<u64>,
        ctx: &mut TxContext,
    ) {
        let bucket_type = BucketType<T> {};
        let well_type = WellType<T> {};
        let tank_type = TankType<T> {};
        assert!(!dof::exists_with_type<BucketType<T>, Bucket<T>>(&protocol.id, bucket_type), EBucketAlreadyExists);
        dof::add(&mut protocol.id, bucket_type, bucket::new<T>(min_collateral_ratio, recovery_mode_threshold, collateral_decimal, max_mint_amount, ctx));
        dof::add(&mut protocol.id, well_type, well::new<T>(ctx));
        dof::add(&mut protocol.id, tank_type, tank::new<BUCK, T>(ctx));
    }

    public entry fun release_bkt<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        bkt_teasury: &mut BktTreasury,
        bkt_reward_amount: u64,
    ) {
        let bkt_for_tank = bkt::release_bkt(bkt_teasury, bkt_reward_amount);
        let tank = borrow_tank_mut<T>(protocol);
        tank::collect_bkt(tank, bkt_for_tank);
    }

    public entry fun update_max_mint_amount<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        max_mint_amount: Option<u64>,
    ) {
        let bucket = borrow_bucket_mut<T>(protocol);
        bucket::update_max_mint_amount(bucket, max_mint_amount);
        let max_mint_amount = if (option::is_some(&max_mint_amount)) {
            option::destroy_some(max_mint_amount)
        } else {
            0
        };
        buck_events::emit_param_updated<BucketProtocol>(
            b"max_mint_amount", max_mint_amount,
        );
    }

    public entry fun update_min_bottle_size(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        min_bottle_size: u64,
    ) {
        protocol.min_bottle_size = min_bottle_size;
        buck_events::emit_param_updated<BucketProtocol>(
            b"min_bottle_size", min_bottle_size,
        );
    }

    public entry fun update_protocol_version(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        version: u64,
    ) {
        protocol.version = version;
        buck_events::emit_param_updated<BucketProtocol>(
            b"version", version,
        );
    }

    public fun borrow_bucket<T>(protocol: &BucketProtocol): &Bucket<T> {
        assert_valid_package_version(protocol);
        let bucket_type = BucketType<T> {};
        assert!(dof::exists_with_type<BucketType<T>, Bucket<T>>(&protocol.id, bucket_type), ENotSupportedType);
        dof::borrow<BucketType<T>, Bucket<T>>(&protocol.id, bucket_type)
    }

    fun borrow_bucket_mut<T>(protocol: &mut BucketProtocol): &mut Bucket<T> {
        assert_valid_package_version(protocol);
        let bucket_type = BucketType<T> {};
        assert!(dof::exists_with_type<BucketType<T>, Bucket<T>>(&protocol.id, bucket_type), ENotSupportedType);
        dof::borrow_mut<BucketType<T>, Bucket<T>>(&mut protocol.id, BucketType<T> {})
    }

    public fun borrow_well<T>(protocol: &BucketProtocol): &Well<T> {
        assert_valid_package_version(protocol);
        let well_type = WellType<T> {};
        assert!(dof::exists_with_type<WellType<T>, Well<T>>(&protocol.id, well_type), ENotSupportedType);
        dof::borrow<WellType<T>, Well<T>>(&protocol.id, WellType<T> {})
    }

    public fun borrow_well_mut<T>(protocol: &mut BucketProtocol): &mut Well<T> {
        assert_valid_package_version(protocol);
        let well_type = WellType<T> {};
        assert!(dof::exists_with_type<WellType<T>, Well<T>>(&protocol.id, well_type), ENotSupportedType);
        dof::borrow_mut<WellType<T>, Well<T>>(&mut protocol.id, WellType<T> {})
    }

    public fun borrow_tank<T>(protocol: &BucketProtocol): &Tank<BUCK, T> {
        assert_valid_package_version(protocol);
        let tank_type = TankType<T> {};
        assert!(dof::exists_with_type<TankType<T>, Tank<BUCK, T>>(&protocol.id, tank_type), ENotSupportedType);
        dof::borrow<TankType<T>, Tank<BUCK, T>>(&protocol.id, TankType<T> {})
    }

    public fun borrow_tank_mut<T>(protocol: &mut BucketProtocol): &mut Tank<BUCK, T> {
        assert_valid_package_version(protocol);
        let tank_type = TankType<T> {};
        assert!(dof::exists_with_type<TankType<T>, Tank<BUCK, T>>(&protocol.id, tank_type), ENotSupportedType);
        dof::borrow_mut<TankType<T>, Tank<BUCK, T>>(&mut protocol.id, TankType<T> {})
    } 

    public fun get_min_bottle_size(protocol: &BucketProtocol): u64 {
        assert_valid_package_version(protocol);  // BUC-2
        protocol.min_bottle_size
    }

    public fun compute_base_rate_fee<T>(bucket: &Bucket<T>, clock: &Clock): u64 {
        let base_rate_fee = bucket::compute_base_rate(bucket, clock::timestamp_ms(clock));
        if (base_rate_fee > constants::max_fee()) base_rate_fee = constants::max_fee();
        if (base_rate_fee < constants::min_fee()) base_rate_fee = constants::min_fee();
        base_rate_fee
    }

    public fun withdraw_surplus_collateral<T>(protocol: &mut BucketProtocol, ctx: &TxContext): Balance<T> {
        assert_valid_package_version(protocol);
        let bucket = borrow_bucket_mut<T>(protocol);
        let debtor = tx_context::sender(ctx);
        bucket::withdraw_surplus_collateral(bucket, debtor)
    }

    fun mint_buck<T>(protocol: &mut BucketProtocol, buck_amount: u64): Balance<BUCK> {
        assert_valid_package_version(protocol);
        buck_events::emit_buck_minted<T>(buck_amount);
        coin::mint_balance(&mut protocol.buck_treasury_cap, buck_amount)
    }

    fun burn_buck<T>(protocol: &mut BucketProtocol, buck: Balance<BUCK>) {
        assert_valid_package_version(protocol);
        buck_events::emit_buck_burnt<T>(balance::value(&buck));
        balance::decrease_supply(coin::supply_mut(&mut protocol.buck_treasury_cap), buck);
    }

    // ======== version 1.2 - flash mint

    // Config for flash mint
    struct FlashMintConfig has key, store {
        id: UID,
        // settings
        fee_rate: u64,
        max_amount: u64,
        // states
        total_amount: u64,
    }

    // Hot-potato
    struct FlashMintReceipt {
        config_id: ID,
        mint_amount: u64,
        fee_amount: u64,
    }

    public fun create_flash_mint_config_to(
        _: &AdminCap,
        fee_rate: u64,
        max_amount: u64,
        to: address,
        ctx: &mut TxContext,
    ) {
        let config = FlashMintConfig {
            id: object::new(ctx),
            fee_rate,
            max_amount,
            total_amount: 0,
        };
        transfer::transfer(config, to);
    }

    public fun share_flash_mint_config(
        _: &AdminCap,
        fee_rate: u64,
        max_amount: u64,
        ctx: &mut TxContext,
    ) {
        let config = FlashMintConfig {
            id: object::new(ctx),
            fee_rate,
            max_amount,
            total_amount: 0,
        };
        transfer::share_object(config);
    }

    public fun update_flash_mint_config(
        _: &AdminCap,
        config: &mut FlashMintConfig,
        fee_rate: u64,
        max_amount: u64,
    ) {
        config.fee_rate = fee_rate;
        buck_events::emit_param_updated<FlashMintConfig>(
            b"fee_rate", fee_rate,
        );
        config.max_amount = max_amount;
        buck_events::emit_param_updated<FlashMintConfig>(
            b"max_amount", max_amount,
        );
    }

    public fun flash_mint(
        protocol: &mut BucketProtocol,
        config: &mut FlashMintConfig,
        mint_amount: u64,
    ): (Balance<BUCK>, FlashMintReceipt) {
        config.total_amount = config.total_amount + mint_amount;
        assert!(config.total_amount <= config.max_amount, EInvalidFlashMintAmount);
        let config_id = object::id(config);
        let fund = mint_buck<BUCK>(protocol, mint_amount);
        let fee_amount = mul_factor(
            mint_amount,
            config.fee_rate,
            constants::fee_precision(),
        );
        let receipt = FlashMintReceipt {
            config_id,
            mint_amount,
            fee_amount,
        };
        buck_events::emit_flash_mint(
            config_id,
            mint_amount,
            fee_amount,
        );
        (fund, receipt)
    }

    public fun flash_burn(
        protocol: &mut BucketProtocol,
        config: &mut FlashMintConfig,
        repayment: Balance<BUCK>,
        receipt: FlashMintReceipt,
    ) {
        let FlashMintReceipt {
            config_id, mint_amount, fee_amount,
        } = receipt;
        assert!(
            balance::value(&repayment) >= mint_amount + fee_amount,
            EFlashBurnNotEnought,
        );
        assert!(
            config_id == object::id(config),
            EFlashMintConfigIdNotMatched,
        );
        config.total_amount = config.total_amount - mint_amount;
        let fee = balance::split(&mut repayment, fee_amount);
        burn_buck<BUCK>(protocol, repayment);
        let buck_well = borrow_well_mut<BUCK>(protocol);
        well_events::emit_collect_fee_from(&fee, b"flashmint");
        well::collect_fee(buck_well, fee);
    }

    // ======== version 1.2 - flash mint

    // ======== version 1.2 - PSM

    struct NoFeePermission has key {
        id: UID,
    }

    struct ReservoirType<phantom T> has copy, drop, store {}

    public fun create_reservoir<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        conversion_rate: u64,
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
        ctx: &mut TxContext,
    ) {
        assert_valid_package_version(protocol);
        let reservoir = reservoir::new<T>(
            conversion_rate,
            charge_fee_rate,
            discharge_fee_rate,
            ctx,
        );
        dof::add(&mut protocol.id, ReservoirType<T> {}, reservoir);
        let well_type = WellType<T> {};
        if (!dof::exists_with_type<WellType<T>, Well<T>>(&protocol.id, well_type)) {
            dof::add(&mut protocol.id, well_type, well::new<T>(ctx));
        };
    }

    public fun borrow_reservoir<T>(protocol: &BucketProtocol): &Reservoir<T> {
        assert_valid_package_version(protocol);
        let reservoir_type = ReservoirType<T> {};
        assert!(dof::exists_with_type<ReservoirType<T>, Reservoir<T>>(&protocol.id, reservoir_type), ENotSupportedType);
        dof::borrow<ReservoirType<T>, Reservoir<T>>(&protocol.id, reservoir_type)
    }

    fun borrow_reservoir_mut<T>(protocol: &mut BucketProtocol): &mut Reservoir<T> {
        assert_valid_package_version(protocol);
        let reservoir_type = ReservoirType<T> {};
        assert!(dof::exists_with_type<ReservoirType<T>, Reservoir<T>>(&protocol.id, reservoir_type), ENotSupportedType);
        dof::borrow_mut<ReservoirType<T>, Reservoir<T>>(&mut protocol.id, reservoir_type)
    }

    public fun update_reservoir_fee_rate<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
    ) {
        assert_valid_package_version(protocol);
        let reservoir = borrow_reservoir_mut<T>(protocol);
        reservoir::update_fee_rate(reservoir, charge_fee_rate, discharge_fee_rate);
        buck_events::emit_param_updated<Reservoir<T>>(
            b"charge_fee_rate", charge_fee_rate,
        );
        buck_events::emit_param_updated<Reservoir<T>>(
            b"discharge_fee_rate", discharge_fee_rate,
        );
    }

    public fun charge_reservoir<T>(
        protocol: &mut BucketProtocol,
        collateral: Balance<T>,
    ): Balance<BUCK> {
        let reservoir = borrow_reservoir<T>(protocol);
        let fee_rate = reservoir::charge_fee_rate(reservoir);
        charge_reservoir_internal(protocol, collateral, fee_rate)
    }

    public fun discharge_reservoir<T>(
        protocol: &mut BucketProtocol,
        buck_input: Balance<BUCK>,
    ): Balance<T> {
        let reservoir = borrow_reservoir<T>(protocol);
        let fee_rate = reservoir::discharge_fee_rate(reservoir);
        discharge_reservoir_internal(protocol, buck_input, fee_rate)
    }
    
    public fun charge_reservoir_without_fee<T>(
        _: &NoFeePermission,
        protocol: &mut BucketProtocol,
        collateral: Balance<T>,
    ): Balance<BUCK> {
        charge_reservoir_internal(protocol, collateral, 0)
    }

    public fun discharge_reservoir_without_fee<T>(
        _: &NoFeePermission,
        protocol: &mut BucketProtocol,
        buck_input: Balance<BUCK>,
    ): Balance<T> {
        discharge_reservoir_internal(protocol, buck_input, 0)
    }

    public fun create_no_fee_permission_to(
        _: &AdminCap,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let permission = NoFeePermission { id: object::new(ctx) };
        transfer::transfer(permission, recipient);
    }

    public fun set_reservoir_partner<T, P: drop>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        charge_fee_rate: u64,
        discharge_fee_rate: u64,
    ) {
        let reservoir = borrow_reservoir_mut<T>(protocol);
        reservoir::set_fee_config<T, P>(reservoir, charge_fee_rate, discharge_fee_rate);
    }

    public fun charge_reservoir_by_partner<T, P: drop>(
        protocol: &mut BucketProtocol,
        collateral: Balance<T>,
        _: P,
    ): Balance<BUCK> {
        let reservoir = borrow_reservoir<T>(protocol);
        let fee_rate = reservoir::charge_fee_rate_for_partner<T, P>(reservoir);
        charge_reservoir_internal(protocol, collateral, fee_rate)
    }

    public fun discharge_reservoir_by_partner<T, P: drop>(
        protocol: &mut BucketProtocol,
        buck_input: Balance<BUCK>,
        _: P,
    ): Balance<T> {
        let reservoir = borrow_reservoir<T>(protocol);
        let fee_rate = reservoir::discharge_fee_rate_for_partner<T, P>(reservoir);
        discharge_reservoir_internal(protocol, buck_input, fee_rate)
    }

    fun charge_reservoir_internal<T>(
        protocol: &mut BucketProtocol,
        collateral: Balance<T>,
        fee_rate: u64,
    ): Balance<BUCK> {
        let reservoir = borrow_reservoir_mut<T>(protocol);
        let buck_amount = reservoir::handle_charge(reservoir, collateral);
        let fee_amount = mul_factor(
            buck_amount,
            fee_rate,
            constants::fee_precision(),
        );
        let output = mint_buck<T>(protocol, buck_amount);
        let fee = balance::split(&mut output, fee_amount);
        let well = borrow_well_mut<BUCK>(protocol);
        well_events::emit_collect_fee_from(&fee, b"charge");
        well::collect_fee(well, fee);
        output
    }

    fun discharge_reservoir_internal<T>(
        protocol: &mut BucketProtocol,
        buck_input: Balance<BUCK>,
        fee_rate: u64,
    ): Balance<T> {
        let buck_amount = balance::value(&buck_input);
        burn_buck<T>(protocol, buck_input);
        let reservoir = borrow_reservoir_mut<T>(protocol);
        let collateral = reservoir::handle_discharge<T>(reservoir, buck_amount);
        let collateral_amount = balance::value(&collateral);
        let fee_amount = mul_factor(collateral_amount, fee_rate, constants::fee_precision());
        let fee = balance::split(&mut collateral, fee_amount);
        let well = borrow_well_mut<T>(protocol);
        well_events::emit_collect_fee_from(&fee, b"discharge");
        well::collect_fee(well, fee);
        collateral
    }

    // ======== version 1.2 - PSM

    // ======== interest

    // === Flask ===

    // collect interests to well
    public fun collect_interests<T>(protocol: &mut BucketProtocol) {
        assert_valid_package_version(protocol);
        let bucket = borrow_bucket_mut<T>(protocol);
        let interest_table = bucket::borrow_interest_table_mut<T>(bucket);
        let interest_payable = interest::collect_interests(interest_table);
        let fee = mint_buck<T>(protocol, interest_payable);
        well_events::emit_collect_fee_from(&fee, b"interest");
        well::collect_fee(borrow_well_mut<BUCK>(protocol), fee);
    }

    #[allow(unused_type_parameter)]
    public fun collect_interests_to_flask<T>(
        _protocol: &mut BucketProtocol,
        _buck_flask: &mut Flask<BUCK>
    ) {
        abort EDeprecated
        // assert_valid_package_version(protocol);
        // let bucket = borrow_bucket_mut<T>(protocol);
        // let interest_table = bucket::borrow_interest_table_mut<T>(bucket);
        // let interest_payable = interest::collect_interests(interest_table);
        // let fee = mint_buck<T>(protocol, interest_payable);

        // sbuck::collect_rewards(buck_flask, fee);
    }

    public fun mint_sbuck(
        _protocol: &mut BucketProtocol,
        _buck_flask: &mut Flask<BUCK>,
        _deposit: Coin<BUCK>
    ): Balance<SBUCK> {
        abort EDeprecated
    }

    public fun burn_sbuck(
        _protocol: &mut BucketProtocol,
        _buck_flask: &mut Flask<BUCK>,
        _shares: Coin<SBUCK>
    ): Balance<BUCK> {
        abort EDeprecated
    }

    // === sBUCK ===

    use flask::float::{Self as f, Float};

    struct SBuckRateKey has store, copy, drop {}

    struct SBuckEmission has key, store {
        id: UID,
        latest_time: u64,
        rate: Float,
    }

    // witness
    struct BUCKET_PROTOCOL has drop {}

    public fun set_sbuck_rate(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        flask: &mut Flask<BUCK>,
        clock: &Clock,
        interest_rate: u64, // bps (ex: 4% -> 400)
        ctx: &mut TxContext,
    ) {
        assert_valid_package_version(protocol);
        let current_time = clock::timestamp_ms(clock);
        if (has_emission(protocol)) {
            collect_interest(protocol, flask, clock);
            let ems = emission_mut(protocol);
            ems.latest_time = current_time;
            ems.rate = f::from_bps(interest_rate);
        } else {
            dof::add(&mut protocol.id, SBuckRateKey {}, SBuckEmission {
                id: object::new(ctx),
                latest_time: current_time,
                rate: f::from_bps(interest_rate),
            });
        };
    }

    public fun interest_amount(
        protocol: &BucketProtocol,
        flask: &Flask<BUCK>,
        clock: &Clock,
    ): u64 {
        if (has_emission(protocol)) {
            let ems = emission(protocol);
            let interval = clock::timestamp_ms(clock) - ems.latest_time;
            let flask_reserves = f::from(sbuck::reserves(flask));
            let interval_frac = f::from_fraction(interval, (constants::ms_in_year() as u64));
            let real_rate = f::mul(ems.rate, interval_frac);
            let amount = f::mul(flask_reserves, real_rate);
            f::floor(amount)
        } else {
            0
        }
    }

    public fun buck_to_sbuck(
        protocol: &mut BucketProtocol,
        flask: &mut Flask<BUCK>,
        clock: &Clock,
        input: Balance<BUCK>,
    ): Balance<SBUCK> {
        assert_valid_package_version(protocol);
        collect_interest(protocol, flask, clock);
        sbuck::deposit_by_protocol(flask, BUCKET_PROTOCOL {}, input)
    }

    public fun sbuck_to_buck(
        protocol: &mut BucketProtocol,
        flask: &mut Flask<BUCK>,
        clock: &Clock,
        input: Balance<SBUCK>,
    ): Balance<BUCK> {
        assert_valid_package_version(protocol);
        collect_interest(protocol, flask, clock);
        sbuck::withdraw_by_protocol(flask, BUCKET_PROTOCOL {}, input)
    }

    fun collect_interest(
        protocol: &mut BucketProtocol,
        flask: &mut Flask<BUCK>,
        clock: &Clock,
    ) {
        let interest_amount = interest_amount(protocol, flask, clock);
        let interest = mint_buck<SBUCK>(protocol, interest_amount);
        let ems = emission_mut(protocol);
        ems.latest_time = clock::timestamp_ms(clock);
        sbuck::collect_rewards(flask, interest);
    }

    fun has_emission(protocol: &BucketProtocol): bool {
        dof::exists_with_type<SBuckRateKey, SBuckEmission>(&protocol.id, SBuckRateKey {})
    }

    fun emission(protocol: &BucketProtocol): &SBuckEmission {
        dof::borrow<SBuckRateKey, SBuckEmission>(&protocol.id, SBuckRateKey {})
    }

    fun emission_mut(protocol: &mut BucketProtocol): &mut SBuckEmission {
        dof::borrow_mut<SBuckRateKey, SBuckEmission>(&mut protocol.id, SBuckRateKey {})
    }

    // === Flask ===

    public fun create_bucket_with_interest_table<T>(
        cap: &AdminCap,
        protocol: &mut BucketProtocol,
        min_collateral_ratio: u64,
        recovery_mode_threshold: u64,
        collateral_decimal: u8,
        max_mint_amount: Option<u64>,
        clock: &Clock,
        interest_rate: u256,
        ctx: &mut TxContext,
    ) {
        create_bucket<T>(cap, protocol, min_collateral_ratio, recovery_mode_threshold, collateral_decimal, max_mint_amount, ctx);
        add_pending_record_to_bucket<T>(cap, protocol, ctx);
        add_interest_table_to_bucket<T>(cap, protocol, clock, ctx);
        set_interest_rate<T>(cap, protocol, interest_rate, clock);
    }

    public fun add_interest_table_to_bucket<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let bucket = borrow_bucket_mut<T>(protocol);
        bucket::add_interest_table_to_bucket(bucket, clock, ctx);
    }

    public fun set_interest_rate<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        new_interest_rate_apr: u256, // 4% (400)
        clock: &Clock,
    ) {
        assert!(new_interest_rate_apr <= 10000, EInvalidInterestRate);
        let bucket = borrow_bucket_mut<T>(protocol);
        let bucket_buck_amount = bucket::get_minted_buck_amount(bucket);
        let bucket_pending_debt = bucket::get_bucket_pending_debt(bucket);
        let interest_table = bucket::borrow_interest_table_mut(bucket);
        let new_interest_rate = mul_factor_u256(
            new_interest_rate_apr,
            constants::interest_precision(), 
            10000 * constants::ms_in_year()
        );
        interest::set_interest_rate(interest_table, new_interest_rate, bucket_buck_amount - bucket_pending_debt, clock);
        buck_events::emit_param_updated<Bucket<T>>(
            b"interest_rate", (new_interest_rate_apr as u64),
        );
    }

    public fun init_bottle_current_interest_index<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        debtor: address,
        ctx: &mut TxContext,
    ) {
        let bucket = borrow_bucket_mut<T>(protocol);
        let interest_table = bucket::borrow_interest_table(bucket);
        let active_interest_index = interest::get_active_interest_index(interest_table);
        bucket::add_interest_index_to_bottle_by_debtor(bucket, debtor, active_interest_index, ctx);
    }

    public fun init_bottle_interest_index<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        debtor: address,
        interest_index: u256,
        ctx: &mut TxContext,
    ) {
        let bucket = borrow_bucket_mut<T>(protocol);
        let interest_table = bucket::borrow_interest_table_mut(bucket);
        assert!(interest_index >= interest::get_active_interest_index(interest_table), EInterestIndexShouldLargeThanCurrent);
        bucket::add_interest_index_to_bottle_by_debtor(bucket, debtor, interest_index, ctx);    
    }

    public fun add_pending_record_to_bucket<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        ctx: &mut TxContext,
     ) {
        let bucket = borrow_bucket_mut<T>(protocol);
        bucket::add_pending_record_to_bucket(bucket, ctx);
    }

    public fun adjust_pending_record<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
    ) {
        use bucket_protocol::bottle;
        use bucket_framework::linked_table;
        let total_pending_coll = 0;
        let total_pending_debt = 0;
        let bucket = borrow_bucket_mut<T>(protocol);
        let bottle_table = bucket::borrow_bottle_table(bucket);
        let table = bottle::borrow_table(bottle_table);
        let curr_debtor = *linked_table::front(table);
        while (option::is_some(&curr_debtor)) {
            let debtor = option::destroy_some(curr_debtor);
            let bottle = bottle::borrow_bottle(bottle_table, debtor);
            total_pending_coll =
                total_pending_coll + bottle::get_pending_coll(bottle, bottle_table);
            total_pending_debt =
                total_pending_debt + bottle::get_pending_debt(bottle, bottle_table);
            let table = bottle::borrow_table(bottle_table);
            curr_debtor = *linked_table::next(table, debtor);
        };
        bucket::adjust_pending_record(bucket, total_pending_coll, total_pending_debt);
    }

    // ======== interest

    // ======== bottle strap

    use bucket_protocol::strap::{Self, BottleStrap};
    public fun borrow_with_strap<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        strap: &BottleStrap<T>,
        clock: &Clock,
        collateral_input: Balance<T>,
        buck_output_amount: u64,
        insertion_place: Option<address>,
        ctx: &mut TxContext,
    ): Balance<BUCK> {
        assert_valid_package_version(protocol);
        // handle collateral
        let min_bottle_size = protocol.min_bottle_size;
        let bucket = borrow_bucket_mut<T>(protocol);
        let strap_fee_rate = strap::fee_rate(strap);
        let fee_rate = if (option::is_none(&strap_fee_rate)) {
            compute_base_rate_fee<T>(bucket, clock)
        } else {
            option::destroy_some(strap_fee_rate)
        };
        let fee_amount = mul_factor(
            buck_output_amount, fee_rate, constants::fee_precision()
        );
        buck_events::emit_collateral_increased<T>(balance::value(&collateral_input));
        let borrower = strap::get_address(strap);
        bucket::handle_borrow(
            bucket,
            oracle,
            borrower,
            clock,
            collateral_input,
            buck_output_amount + fee_amount,
            insertion_place,
            min_bottle_size,
            ctx,
        );
        if (fee_amount > 0) {
            let fee = mint_buck<T>(protocol, fee_amount);
            well_events::emit_collect_fee_from(&fee, b"borrow");
            well::collect_fee(borrow_well_mut<BUCK>(protocol), fee);
        };
        mint_buck<T>(protocol, buck_output_amount)
    }

    public fun withdraw_with_strap<T>(
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        strap: &BottleStrap<T>,
        clock: &Clock,
        collateral_amount: u64,
        insertion_place: Option<address>,
    ): Balance<T> {
        let bucket = borrow_bucket_mut<T>(protocol);
        assert!(bucket::is_not_locked(bucket), EBucketLocked);   
        buck_events::emit_collateral_decreased<T>(collateral_amount);
        let debtor = strap::get_address(strap);
        bucket::handle_withdraw(bucket, oracle, debtor, clock, collateral_amount, insertion_place)
    }
    
    public fun repay_with_strap<T>(
        protocol: &mut BucketProtocol,
        strap: &BottleStrap<T>,
        buck_input: Balance<BUCK>,
        clock: &Clock,
    ): Balance<T> {
        assert_valid_package_version(protocol);
        let min_bottle_size = protocol.min_bottle_size;
        let debtor = strap::get_address(strap);
        let buck_input_amount = balance::value(&buck_input);

        // burn BUCK
        burn_buck<T>(protocol, buck_input);
        // return collateral
        let bucket = borrow_bucket_mut<T>(protocol);
        assert!(bucket::is_not_locked(bucket), EBucketLocked);
        let collateral_output = bucket::handle_repay<T>(bucket, debtor, buck_input_amount, min_bottle_size, true, clock);
        buck_events::emit_collateral_decreased<T>(balance::value(&collateral_output));
        collateral_output
    }

    public fun withdraw_surplus_with_strap<T>(
        protocol: &mut BucketProtocol,
        strap: &BottleStrap<T>,
    ): Balance<T> {
        assert_valid_package_version(protocol);
        let bucket = borrow_bucket_mut<T>(protocol);
        let debtor = strap::get_address(strap);
        bucket::withdraw_surplus_collateral(bucket, debtor)
    }

    public fun new_strap_with_fee_rate_to<T>(
        _: &AdminCap,
        fee_rate: u64,
        to: address,
        ctx: &mut TxContext,
    ) {
        let strap = strap::new_with_fee_rate<T>(fee_rate, ctx);
        transfer::public_transfer(strap, to);
    }

    public fun update_liquidation_config<T>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        oracle: &BucketOracle,
        clock: &Clock,
        min_collateral_ratio: u64,
        recovery_mode_threshold: u64,
    ) {
        let bucket = borrow_bucket_mut<T>(protocol);
        bucket::update_liquidation_config(
            bucket, min_collateral_ratio, recovery_mode_threshold,
        );
        assert!(
            !bucket::has_liquidatable_bottle(bucket, oracle, clock),
            ECannotChangeLiquidationConfig,
        );
        buck_events::emit_param_updated<T>(
            b"min_collateral_ratio", min_collateral_ratio,
        );
        buck_events::emit_param_updated<T>(
            b"recovery_mode_threshold", recovery_mode_threshold,
        );
    }

    // ======== bottle strap

    // ======== package version

    struct TestVersion has key, store {
        id: UID,
        version: u64,
    }

    public fun package_version(): u64 { PACKAGE_VERSION }

    public fun add_test_version(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        version: u64,
        ctx: &mut TxContext,
    ) {
        let key = b"test_version";
        dof::add<vector<u8>, TestVersion>(
            &mut protocol.id,
            key,
            TestVersion { id: object::new(ctx), version }
        );
    }

    public fun remove_test_version(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
    ) {
        let key = b"test_version";
        let test_version = dof::remove<vector<u8>, TestVersion>(
            &mut protocol.id, key,
        );
        let TestVersion { id, version } = test_version;
        object::delete(id);
        protocol.version = version;
    }

    fun assert_valid_package_version(protocol: &BucketProtocol) {
        let package_version = package_version();
        let key = b"test_version";
        let has_test_version = dof::exists_with_type<vector<u8>, TestVersion>(&protocol.id, key);
        if (has_test_version) {
            let test_version = dof::borrow<vector<u8>, TestVersion>(
                &protocol.id, key,
            );
            assert!(
                package_version == protocol.version ||
                package_version == test_version.version
            , EInvalidPackageVersion);
        } else {
            assert!(
                package_version == protocol.version
            , EInvalidPackageVersion);
        };
    }

    // ======== package version

    // ======== pipe
    use bucket_protocol::pipe::{Self, PipeType, Pipe, OutputCarrier, InputCarrier};

    public fun create_pipe<T, R: drop>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
        ctx: &mut TxContext,
    ) {
        let pipe_type = pipe::new_type<T, R>();
        let pipe = pipe::new_pipe<T, R>(ctx);
        dof::add(&mut protocol.id, pipe_type, pipe);
    }

    public fun destroy_pipe<T, R: drop>(
        _: &AdminCap,
        protocol: &mut BucketProtocol,
    ) {
        if (is_buck<T>()) {
            let pipe_type = pipe::new_type<T, R>();
            let pipe = dof::remove<PipeType<T, R>, Pipe<T, R>>(&mut protocol.id, pipe_type);
            pipe::destroy_buck_pipe(pipe);            
        } else {
            let pipe_type = pipe::new_type<T, R>();
            let pipe = dof::remove<PipeType<T, R>, Pipe<T, R>>(&mut protocol.id, pipe_type);
            pipe::destroy_pipe(pipe);
        };
    }

    public fun borrow_pipe<T, R: drop>(protocol: &BucketProtocol): &Pipe<T, R> {
        assert_valid_package_version(protocol);
        let pipe_type = pipe::new_type<T, R>();
        assert!(dof::exists_with_type<PipeType<T, R>, Pipe<T, R>>(&protocol.id, pipe_type), ENotSupportedType);
        dof::borrow<PipeType<T, R>, Pipe<T, R>>(&protocol.id, pipe_type)
    }

    fun borrow_pipe_mut<T, R: drop>(protocol: &mut BucketProtocol): &mut Pipe<T, R> {
        assert_valid_package_version(protocol);
        let pipe_type = pipe::new_type<T, R>();
        assert!(dof::exists_with_type<PipeType<T, R>, Pipe<T, R>>(&protocol.id, pipe_type), ENotSupportedType);
        dof::borrow_mut<PipeType<T, R>, Pipe<T, R>>(&mut protocol.id, pipe_type)
    }

    public fun output<T, R: drop>(
        protocol: &mut BucketProtocol,
        volume: u64,
    ): OutputCarrier<T, R> {
        assert!(!is_buck<T>(), ECannotUseNormalPipeForBuck);
        let bucket_mut = borrow_bucket_mut<T>(protocol);
        let content = bucket::output(bucket_mut, volume);
        let pipe_mut = borrow_pipe_mut<T, R>(protocol);
        pipe::output(pipe_mut, content)
    }

    public fun input<T, R: drop>(
        protocol: &mut BucketProtocol,
        carrier: InputCarrier<T, R>,
    ) {
        assert!(!is_buck<T>(), ECannotUseNormalPipeForBuck);
        let pipe_mut = borrow_pipe_mut<T, R>(protocol);
        let content = pipe::destroy_input_carrier(pipe_mut, carrier);
        let bucket_mut = borrow_bucket_mut<T>(protocol);
        bucket::input(bucket_mut, content);
    }

    public fun output_buck<R: drop>(
        protocol: &mut BucketProtocol,
        volume: u64,
    ): OutputCarrier<BUCK, R> {
        let content = mint_buck<R>(protocol, volume);
        let pipe_mut = borrow_pipe_mut<BUCK, R>(protocol);
        pipe::output(pipe_mut, content)
    }

    public fun input_buck<R: drop>(
        protocol: &mut BucketProtocol,
        carrier: InputCarrier<BUCK, R>,
    ) {
        let pipe_mut = borrow_pipe_mut<BUCK, R>(protocol);
        let content = pipe::destroy_input_carrier(pipe_mut, carrier);
        burn_buck<R>(protocol, content);
    }

    public fun is_buck<T>(): bool {
        use std::type_name::get;
        get<T>() == get<BUCK>()
    }

    // ======== pipe

    // ======== surplus

    public fun deposit_surplus_with_strap<T>(
        protocol: &mut BucketProtocol,
        collateral: Balance<T>,
        strap: &BottleStrap<T>,
        ctx: &mut TxContext,
    ) {
        let coll_value = balance::value(&collateral);
        let strap_addr = strap::get_address(strap);
        let bucket = borrow_bucket_mut<T>(protocol);
        bucket::handle_deposit_surplus(bucket, strap_addr, collateral, ctx);
        buck_events::emit_collateral_increased<T>(coll_value);
    }

    // ======== surplus

    // ======== transfer_bottle

    public fun transfer_bottle<T>(
        protocol: &mut BucketProtocol,
        clock: &Clock,
        new_debtor: address,
        ctx: &TxContext,
    ) {
        let bucket = borrow_bucket_mut<T>(protocol);
        let debtor = tx_context::sender(ctx);
        bucket::handle_transfer(bucket, debtor, new_debtor, clock);
    }

    // ======== transfer_bottle

    // Test-only

    #[test_only]
    public fun new_for_testing(witness: BUCK, ctx: &mut TxContext): (BucketProtocol, AdminCap) {
        new_protocol(witness, ctx)
    }

    #[test_only]
    #[lint_allow(share_owned)]
    public fun share_for_testing(witness: BUCK, admin: address, ctx: &mut TxContext) {
        let (protocol, admin_cap) = new_protocol(witness, ctx);
        transfer::share_object(protocol);
        transfer::transfer(admin_cap, admin);
    }

    #[test_only]
    #[lint_allow(share_owned)]
    public fun share_for_testing_with_interest(witness: BUCK, admin: address, clock: &Clock, ctx: &mut TxContext) {
        let (protocol, admin_cap) = new_protocol_with_interest(witness, clock, ctx);
        transfer::share_object(protocol);
        transfer::transfer(admin_cap, admin);
    }

    #[test_only]
    public fun destroy_for_testing(admin_cap: AdminCap) {
        let AdminCap { id } = admin_cap;
        object::delete(id);
    }

    #[test]
    fun test_buck_init() {
        use sui::test_scenario;
        use std::vector;

        let dev = @0xde1;
        let scenario_val = test_scenario::begin(dev);
        let scenario = &mut scenario_val;
        {
            init(BUCK {}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, dev);
        {
            assert!(test_scenario::has_most_recent_shared<BucketProtocol>(), 0);
            assert!(vector::length(&test_scenario::ids_for_sender<AdminCap>(scenario)) == 1, 0);
        };

        test_scenario::end(scenario_val);
    }
}
