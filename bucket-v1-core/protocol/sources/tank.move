/*
 * The Tank holds BUCK coins deposited by Tank contributors.
 *
 * When a bottle is liquidated, then depending on system conditions, some of its BUCK debt gets offset with
 * BUCK in the Tank: that is, the offset debt evaporates, and an equal amount of BUCK in the Tank is burned.
 *
 * Thus, a liquidation causes each depositor to receive a BUCK loss, in proportion to their deposit as a share of total deposits.
 * They also receive a gain, as the SUI collateral of the liquidated bottle is distributed among Tank contributors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total BUCK in the Tank, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range (0,1)
 *
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and collateral gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and collateral gain, we simply update two state variables:
 * a product P, and a sum S.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated collateral gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Tank, they get a snapshot of the latest P and S: start_p and start_s, respectively.
 *
 * For a given deposit deposit_amount, the ratio current_p/start_p tells us the factor by which a deposit has decreased since it joined the Tank,
 * and the term deposit_amount * (current_s - start_s)/start_p gives us the deposit's total accumulated collateral gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding collateral gain
 * can be calculated using the initial deposit, the depositors' snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated collateral gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range (0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range (0,1).
 * Unfortunately, floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Tank (and thus each multiply P by a very small number in range (0,1) ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Tank hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0),
 * we first multiply P by 1e9, and increment a current_scale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the 
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the 
 * order of 1e-9. 
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Tank, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Tank is emptied by a liquidation, we reset P = 1 and current_scale = 0, and increment the current_epoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the current_epoch and the current_scale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by deposit_amount * current_p /start_p.
 * If it spans one scale change, it is given by deposit_amount * current_p / (start_p * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion BUCK has depleted to < 1 BUCK).
 *
 *
 *  --- TRACKING DEPOSITOR'S COLLATERAL GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated collateral gain, during the epoch in which the deposit was non-zero and earned SUI.
 *
 * We calculate the depositor's accumulated collateral gain for the scale at which they made the deposit, using the collateral gain formula:
 * collateral_amount1 = deposit_amount * (current_s - start_s)/start_p
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * collateral_amount2 = deposit_amount * current_s / (start_p * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (collateral_amount1 + collateral_amount2) captures the depositor's total accumulated collateral gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 */

module bucket_protocol::tank {

    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::package;
    use sui::dynamic_field as df;

    use bucket_framework::math::mul_factor;
    use bucket_protocol::bkt::{Self, BKT, BktTreasury};
    use bucket_protocol::constants;
    use bucket_protocol::tank_events as events;

    friend bucket_protocol::buck;

    /// Errors
    const ETankLocked: u64 = 0;
    const EFlashFeeNotEnough: u64 = 1;
    const EInvalidEpoch: u64 = 3;
    const EInvalidP: u64 = 4;
    const ETankEmpty: u64 = 6;
    const ECannotDepositZero: u64 = 7;
    const EDepositAndWithdrawInSameTxn: u64 = 8;
    public fun err_deposit_and_withdraw_in_same_txn() { abort EDepositAndWithdrawInSameTxn }

    struct Tank<phantom BUCK, phantom T> has store, key {
        id: UID,
        reserve: Balance<BUCK>,
        collateral_pool: Balance<T>,
        current_p: u64,
        /// With each offset that fully empties the Tank, the epoch is incremented by 1
        current_epoch: u64,
        /// The sums are stored in a Table ({epoch, scale} => sum)
        epoch_scale_sum_map: Table<EpochAndScale, u64>,
        /// Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
        current_scale: u64,
        /// for BKT reward
        bkt_pool: Balance<BKT>,
        /// The gain is used to calculate BKT gains
        epoch_scale_gain_map: Table<EpochAndScale, u64>,
        /// flash loan
        total_flash_loan_amount: u64,
    }

    struct ContributorToken<phantom BUCK, phantom T> has store, key {
        id: UID,
        deposit_amount: u64,
        start_p: u64,
        start_s: u64,
        start_g: u64,
        start_epoch: u64,
        start_scale: u64,
        ctx_epoch: u64,
    }

    struct FlashReceipt<phantom BUCK, phantom T> {
        amount: u64,
        fee: u64,
    }

    struct EpochAndScale has store, copy, drop {
        epoch: u64,
        scale: u64,
    }

    struct DigestKey has copy, drop, store {}

    struct TANK has drop {}

    fun init(otw: TANK, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    public fun new_table(ctx: &mut TxContext): Table<EpochAndScale, u64> {
        table::new<EpochAndScale, u64>(ctx)
    }

    fun add_table(table: &mut Table<EpochAndScale, u64>, epoch: u64, scale: u64) {
        if (!table::contains(table, EpochAndScale { epoch: epoch, scale: scale,})) {
            table::add(table, EpochAndScale {
                epoch: epoch,
                scale: scale,
            }, 0);
        };
    }

    public(friend) fun new<BUCK, T>(ctx: &mut TxContext): Tank<BUCK, T> {
        Tank {
            id: object::new(ctx),
            reserve: balance::zero(),
            collateral_pool: balance::zero(),
            current_p: constants::p_initial_value(),
            current_epoch: 0,
            epoch_scale_sum_map: new_table(ctx),
            current_scale: 0,
            bkt_pool: balance::zero(),
            epoch_scale_gain_map: new_table(ctx),
            total_flash_loan_amount: 0,
        }
    }

    public(friend) fun collect_bkt<BUCK, T>(tank: &mut Tank<BUCK, T>, bkt_input: Balance<BKT>) {
        let bkt_amount = balance::value(&bkt_input);
        let tank_reserve_amount = get_reserve_balance(tank);
        balance::join(&mut tank.bkt_pool, bkt_input);
        add_table(&mut tank.epoch_scale_gain_map, tank.current_epoch, tank.current_scale);
        let current_g_cache = table::borrow_mut(&mut tank.epoch_scale_gain_map, EpochAndScale {
            epoch: tank.current_epoch,
            scale: tank.current_scale,
        });
        *current_g_cache = *current_g_cache + mul_factor(
            tank.current_p,
            bkt_amount,
            tank_reserve_amount,
        );
        events::emit_collect_bkt<T>(bkt_amount);
    }

    /// Deposit BUCK into Tank
    /// @param tank The tank to deposit into
    /// @param deposit_input The BUCK deposit amount
    /// @param ctx
    /// @return ContributorToken The contributor token that records the deposit information
    /// - Add the BUCK to the tank reserve
    /// - Record the deposit amount, start p, start s, start g, start epoch, start scale to the contributor token
    public fun deposit<BUCK, T>(
        tank: &mut Tank<BUCK, T>,
        deposit_input: Balance<BUCK>,
        ctx: &mut TxContext,
    ): ContributorToken<BUCK, T> {
        assert!(is_not_locked(tank), ETankLocked);
        assert!(balance::value(&deposit_input) > 0, ECannotDepositZero);
        let deposit_amount = balance::value(&deposit_input);
        events::emit_deposit<T>(deposit_amount);
        balance::join(&mut tank.reserve, deposit_input);
        let epoch_scale = EpochAndScale {
            epoch: tank.current_epoch,
            scale: tank.current_scale,
        };
        add_table(&mut tank.epoch_scale_sum_map, tank.current_epoch, tank.current_scale);
        let current_s_cache = table::borrow(&tank.epoch_scale_sum_map, epoch_scale);
        add_table(&mut tank.epoch_scale_gain_map, tank.current_epoch, tank.current_scale);
        let current_g_cache = table::borrow(&tank.epoch_scale_gain_map, epoch_scale);
        let id = object::new(ctx);
        df::add(&mut id, DigestKey {}, *tx_context::digest(ctx));
        ContributorToken {
            id,
            deposit_amount,
            start_p: tank.current_p,
            start_s: *current_s_cache,
            start_g: *current_g_cache,
            start_epoch: tank.current_epoch,
            start_scale: tank.current_scale,
            ctx_epoch: tx_context::epoch(ctx),
        }
    }

    // --- Liquidation function ---
    /// Offset the specified debt against the BUCK contained in the Tank
    /// @param tank The tank
    /// @param collateral_input The collateral to add to the tank
    /// @param debt_amount The amount of debt to offset
    /// @param ctx
    /// @return Balance<BUCK>
    /// - Update the current s, current p
    /// - Add collateral to the tank
    /// - Remove BUCK from the tank
    public(friend) fun absorb<BUCK, T>(
        tank: &mut Tank<BUCK, T>,
        collateral_input: Balance<T>,
        debt_amount: u64,
    ): Balance<BUCK> {
        let collateral_amount = balance::value(&collateral_input);
        let tank_reserve_amount = balance::value(&tank.reserve);
        let debt_reserve_diff = tank_reserve_amount - debt_amount;

        assert!(tank_reserve_amount > 0, ETankEmpty);

        add_table(
            &mut tank.epoch_scale_sum_map, 
            tank.current_epoch, 
            tank.current_scale
        );
        let current_s_cache = table::borrow_mut(&mut tank.epoch_scale_sum_map, EpochAndScale {
            epoch: tank.current_epoch,
            scale: tank.current_scale,
        });
        // Calculate the new S first, before we update P
        // The gain for any given depositor from a liquidation depends on the value of their deposit
        // (and the value of total deposit) prior to the Stability being depleted by the debt in the liquidation.
        // Since S corresponds to collateral gain, and P to deposit loss, we update S first
        *current_s_cache = *current_s_cache + mul_factor(
            tank.current_p,
            collateral_amount,
            tank_reserve_amount,
        );

        let new_p = mul_factor(
            tank.current_p, 
            debt_reserve_diff, 
            tank_reserve_amount
        );
        
        // Tank-emptying liquidation, BUCK = 0, reset the P to 1 and S to 0, epoch + 1
        if (debt_reserve_diff == 0) {
            tank.current_epoch = tank.current_epoch + 1;
            tank.current_p = constants::p_initial_value();
            tank.current_scale = 0;
            add_table(
                &mut tank.epoch_scale_sum_map,
                tank.current_epoch,
                tank.current_scale
            );
        }
        // If multiplying P by a non-zero product factor would reduce P below the scale boundary (1e9), scale + 1
        else if (new_p < constants::scale_factor()) {
            new_p = new_p * constants::scale_factor();
            tank.current_p = new_p;
            tank.current_scale = tank.current_scale + 1;
            add_table(
                &mut tank.epoch_scale_sum_map, 
                tank.current_epoch, 
                tank.current_scale
            );
        }
        else {
            tank.current_p = new_p;
        };
        
        assert!(tank.current_p > 0, EInvalidP);

        events::emit_absorb<T>(debt_amount, collateral_amount);
        events::emit_tank_update<T>(tank.current_epoch, tank.current_scale, tank.current_p);

        balance::join(&mut tank.collateral_pool, collateral_input);
        balance::split(&mut tank.reserve, debt_amount)
    }

    /// Withdraw BUCK and collateral gain from the Tank
    /// @param tank The tank
    /// @param token The contributor token
    /// @return (buck_withdrawal, collateral_withdrawal) The BUCK and collateral withdrawal balance
    public(friend) fun withdraw<BUCK, T>(
        tank: &mut Tank<BUCK, T>,
        bkt_treasury: &mut BktTreasury,
        token: ContributorToken<BUCK, T>,
        ctx: &TxContext,
    ): (Balance<BUCK>, Balance<T>, Balance<BKT>) {
        let buck_withdrawal_amount = get_token_weight(tank, &token);
        let buck_withdrawal = balance::split(&mut tank.reserve, buck_withdrawal_amount);
        let (collateral_withdrawal, bkt_reward) = claim(tank, bkt_treasury, &mut token, ctx);
        let ContributorToken { id, deposit_amount: _, start_p: _, start_s: _, start_g: _, start_epoch: _, start_scale: _, ctx_epoch: _} = token;
        let digest_key = DigestKey {};
        if (df::exists_with_type<DigestKey, vector<u8>>(&id, digest_key)) {
            let digest = df::remove<DigestKey, vector<u8>>(&mut id, digest_key);
            if (get_reserve_balance(tank) > 0 && digest == *tx_context::digest(ctx))
                err_deposit_and_withdraw_in_same_txn();
        };
        object::delete(id);
        
        events::emit_withdraw<T>(
            buck_withdrawal_amount,
            balance::value(&buck_withdrawal),
            balance::value(&bkt_reward),
        );

        (buck_withdrawal, collateral_withdrawal, bkt_reward)
    }

    /// Claim collateral gain and BKT reward from the Tank
    /// @param tank The tank
    /// @param token The contributor token
    /// @return Balance<T> The collateral withdrawal balance
    public fun claim<BUCK, T>(
        tank: &mut Tank<BUCK, T>,
        bkt_treasury: &mut BktTreasury,
        token: &mut ContributorToken<BUCK, T>,
        ctx: &TxContext,
    ): (Balance<T>, Balance<BKT>) {

        // check bkt has been claimed
        let bkt_reward = claim_bkt<BUCK, T>(tank, token);

        add_table(&mut tank.epoch_scale_sum_map, token.start_epoch, token.start_scale + 1);
        let collateral_amount  = get_collateral_reward_amount(tank, token);

        let current_s = table::borrow(&tank.epoch_scale_sum_map, EpochAndScale {
            epoch: tank.current_epoch,
            scale: tank.current_scale,
        });

        add_table(&mut tank.epoch_scale_gain_map, tank.current_epoch, tank.current_scale);
        let current_g = table::borrow(&tank.epoch_scale_gain_map, EpochAndScale {
            epoch: tank.current_epoch,
            scale: tank.current_scale,
        });

        token.deposit_amount = get_token_weight(tank, token);
        token.start_s = *current_s;
        token.start_p = tank.current_p;
        token.start_g = *current_g;
        token.start_epoch = tank.current_epoch;
        token.start_scale = tank.current_scale;

        events::emit_withdraw<T>(
            0,
            collateral_amount,
            balance::value(&bkt_reward),
        );

        if (tx_context::epoch(ctx) - token.ctx_epoch > 7) {
            (balance::split(&mut tank.collateral_pool, collateral_amount), bkt_reward)
        } else {
            bkt::collect_bkt(bkt_treasury, bkt_reward);
            (balance::split(&mut tank.collateral_pool, collateral_amount), balance::zero<BKT>())
        }
    }

    /// Claim BKT reward earned by a deposit since its last snapshots were taken
    /// @param tank The tank
    /// @param token The contributor token
    /// @return Balance<BKT> The BKT withdrawal balance
    fun claim_bkt<BUCK, T>(
        tank: &mut Tank<BUCK, T>,
        token: &ContributorToken<BUCK, T>,
    ): Balance<BKT> {
        
        add_table(&mut tank.epoch_scale_gain_map, token.start_epoch, token.start_scale);
        add_table(&mut tank.epoch_scale_gain_map, token.start_epoch, token.start_scale + 1);
        
        let bkt_output_amount = get_bkt_reward_amount(tank, token);

        balance::split(&mut tank.bkt_pool, bkt_output_amount)
    }

    public fun airdrop_collateral<BUCK, T>(tank: &mut Tank<BUCK, T>, collateral_input: Balance<T>) {
        balance::join(&mut tank.collateral_pool, collateral_input);
    }

    public fun airdrop_bkt<BUCK, T>(tank: &mut Tank<BUCK, T>, bkt_input: Balance<BKT>) {
        balance::join(&mut tank.bkt_pool, bkt_input);
    }

    public fun get_reserve_balance<BUCK, T>(tank: &Tank<BUCK, T>): u64 {
        balance::value(&tank.reserve)
    }

    public fun get_bkt_pool_balance<BUCK, T>(tank: &Tank<BUCK, T>) : u64 {
        balance::value(&tank.bkt_pool)
    }

    public fun get_collateral_pool_balance<BUCK, T>(tank: &Tank<BUCK, T>): u64 {
        balance::value(&tank.collateral_pool)
    }

    public fun get_bkt_reward_amount<BUCK, T>(tank: &Tank<BUCK, T>, token: &ContributorToken<BUCK, T>): u64 {
        if (token.deposit_amount == 0) {
            return 0
        };

        let g_cache = table::borrow(&tank.epoch_scale_gain_map, EpochAndScale {
            epoch: token.start_epoch,
            scale: token.start_scale,
        });
        let sec_portion = if (table::contains(&tank.epoch_scale_gain_map, EpochAndScale {
            epoch: token.start_epoch,
            scale: token.start_scale + 1,
        })) {
            let next_g_cache = table::borrow(&tank.epoch_scale_gain_map, EpochAndScale {
                epoch: token.start_epoch,
                scale: token.start_scale + 1,
            });

            *next_g_cache / constants::scale_factor()
        } else {
            0
        };

        let bkt_output_amount = mul_factor(
            token.deposit_amount,
            *g_cache - token.start_g + sec_portion,
            token.start_p,
        );

        bkt_output_amount
    }

    public fun get_collateral_reward_amount<BUCK, T>(tank: &Tank<BUCK, T>, token: &ContributorToken<BUCK, T>): u64 {
        
        let epoch_scale = EpochAndScale {
            epoch: token.start_epoch,
            scale: token.start_scale,
        };
        assert!(table::contains(&tank.epoch_scale_sum_map, epoch_scale), EInvalidEpoch);     

        let next_s_cache = if (!table::contains(&tank.epoch_scale_sum_map, EpochAndScale {
                epoch: token.start_epoch,
                scale: token.start_scale + 1,
            })) {
            0
        } else {
            let next_s = table::borrow(&tank.epoch_scale_sum_map, EpochAndScale {
                epoch: token.start_epoch,
                scale: token.start_scale + 1,
            });
            *next_s
        };
        
        // Grab the sum 'S' from the epoch at which the stake was made. The collateral gain may span up to one scale change.
        // If it does, the second portion of the gain is scaled by 1e9.
        // If the gain spans no scale change, the second portion will be 0.
        let s_cache = table::borrow(&tank.epoch_scale_sum_map, epoch_scale);

        let sec_portion = next_s_cache / constants::scale_factor();
        let collateral_amount = mul_factor(
            token.deposit_amount,
            *s_cache - token.start_s + sec_portion,
            token.start_p,
        );
        
        collateral_amount
    }

    /// Get compounded stack (BUCK), given by the formula: deposit = deposit_amount * current_p / start_p
    public fun get_token_weight<BUCK, T>(tank: &Tank<BUCK, T>, token: &ContributorToken<BUCK, T>): u64 {

        // if the stake was made before a tank-emptying event, stack = 0
        if (token.start_epoch < tank.current_epoch) {
            return 0
        };

        // If a scale change in P was made during the stake's lifetime, account for it.
        // If more than one scale change was made, then the stake has decreased by a factor of
        // at least 1e-9 -- so return 0.
        let scale_diff = tank.current_scale - token.start_scale;
        let compound_stake = if (scale_diff == 0) {
            mul_factor(token.deposit_amount, tank.current_p, token.start_p)
        } else if (scale_diff == 1){
            mul_factor(token.deposit_amount, tank.current_p, token.start_p) / constants::scale_factor()
        } else { // more than one scale, the stake has decreased by a factor of at least 1e-9
            0
        };

        compound_stake
    }

    /// Flash loan
    /// @param tank The tank
    /// @param amount The amount of BUCK to borrow
    /// @return (Balance<BUCK>, FlashReceipt<BUCK, T>) The borrowed BUCK and the receipt
    public(friend) fun handle_flash_borrow<BUCK, T>(
        tank: &mut Tank<BUCK, T>,
        amount: u64,
    ): (Balance<BUCK>, FlashReceipt<BUCK, T>) {
        tank.total_flash_loan_amount = tank.total_flash_loan_amount + amount;
        let fee = mul_factor(amount, constants::flash_loan_fee(), constants::fee_precision());
        if (fee == 0) fee = 1;
        (balance::split(&mut tank.reserve, amount), FlashReceipt { amount, fee })
    }

    /// Repay the flash loan
    /// @param tank The tank
    /// @param repayment The repayment amount
    /// @param receipt The flash loan receipt
    /// @return Balance<BUCK>
    public(friend) fun handle_flash_repay<BUCK, T>(
        tank: &mut Tank<BUCK, T>,
        repayment: Balance<BUCK>,
        receipt: FlashReceipt<BUCK, T>,
    ): Balance<BUCK> {
        let FlashReceipt { amount, fee } = receipt;
        tank.total_flash_loan_amount = tank.total_flash_loan_amount - amount;
        assert!(balance::value(&repayment) >= amount + fee, EFlashFeeNotEnough);
        let repayment_to_reserve = balance::split(&mut repayment, amount);
        balance::join(&mut tank.reserve, repayment_to_reserve);
        repayment
    }

    public fun is_not_locked<BUCK, T>(tank: &Tank<BUCK, T>): bool {
        tank.total_flash_loan_amount == 0
    }

    public fun get_total_flash_loan_amount<BUCK, T>(tank: &Tank<BUCK, T>): u64 {
        tank.total_flash_loan_amount
    }

    public fun get_receipt_info<BUCK, T>(receipt: &FlashReceipt<BUCK, T>): (u64, u64) {
        (receipt.amount, receipt.fee)
    }

    public fun get_current_p<BUCK, T>(tank: &Tank<BUCK, T>): u64 {
        tank.current_p
    }

    public fun get_current_scale<BUCK, T>(tank: &Tank<BUCK, T>): u64 {
        tank.current_scale
    }

    public fun get_current_epoch<BUCK, T>(tank: &Tank<BUCK, T>): u64 {
        tank.current_epoch
    }

    public fun get_token_ctx_epoch<BUCK, T>(token: &ContributorToken<BUCK, T>): u64 {
        token.ctx_epoch
    }

    public fun get_epoch_scale_sum_map<BUCK, T>(tank: &Tank<BUCK, T>, epoch: u64, scale: u64): u64 {
        *table::borrow(
    &tank.epoch_scale_sum_map, 
        EpochAndScale {
            epoch: epoch,
            scale: scale,
        })
    }

    public fun get_epoch_scale_gain_map<BUCK, T>(tank: &Tank<BUCK, T>, epoch: u64, scale: u64): u64 {
        *table::borrow(
    &tank.epoch_scale_gain_map, 
        EpochAndScale {
            epoch: epoch,
            scale: scale,
        })
    }

    public fun get_contributor_token_value<BUCK, T>(token: &ContributorToken<BUCK, T>
    ): (u64, u64, u64, u64, u64, u64) {
        (
            token.deposit_amount,
            token.start_p,
            token.start_s,
            token.start_g,
            token.start_epoch,
            token.start_scale,
        )
    }

    #[test]
    fun test_publisher() {
        use sui::test_scenario;
        use sui::test_utils;
        use sui::package::{Self, Publisher};

        let dev = @0x123;

        let scenario_val = test_scenario::begin(dev);
        let scenario = &mut scenario_val;
        {
            init(test_utils::create_one_time_witness<TANK>(),test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, dev);
        {
            let publisher = test_scenario::take_from_sender<Publisher>(scenario);
            assert!(package::from_package<TANK>(&publisher), 0);
            assert!(package::from_module<TANK>(&publisher), 0);
            test_scenario::return_to_sender(scenario, publisher);
        };

        test_scenario::end(scenario_val);
    }

}
