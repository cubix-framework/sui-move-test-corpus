module bucket_protocol::bkt {

    use sui::tx_context::TxContext;
    use sui::coin;
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::balance::{Self, Supply, Balance};
    use sui::url;
    use std::option;

    friend bucket_protocol::buck;

    // 0xbb7e63ea8820707968c5c9879c5e3a8ac6ffe59337c7e307490089b8c6caf6ef (weight 1)
    // 0xd3d254db2917ed89ecbcdc8039138a946733b937b8716ffc7aa3ce18c64cc26e (weight 1)
    // 0x0c87f96e5b09faebc286a2180e977003313c4467a9e95bbc3b6c5c6d711f67ae (weight 1)
    // threshold 3
    const MULTI_SIG_ADDRESS: address = @0x169451f78c5f099a57b0126902a7e61a0c9dace2a8e40caa16168e874d0f0156;

    const BKT_TOTAL_SUPPLY: u64 = 100_000_000; // 100M

    // Ecosystem
    const ECO_ALLOCATION: u64 = 30_000_000; // 30M

    struct BKT has drop {}

    struct BktTreasury has key {
        id: UID,
        eco_part: Balance<BKT>,
        bkt_supply: Supply<BKT>,
    }

    struct BktAdminCap has key, store { id: UID }

    #[lint_allow(share_owned)]
    fun init(witness: BKT, ctx: &mut TxContext) {
        let (bkt_treasury, admin_cap) = new_treasury(witness, ctx);
        transfer::share_object(bkt_treasury);
        transfer::transfer(admin_cap, MULTI_SIG_ADDRESS);
    }

    fun new_treasury(witness: BKT, ctx: &mut TxContext): (BktTreasury, BktAdminCap) {
        let (bkt_treasury_cap, bkt_metadata) = coin::create_currency(
            witness,
            3,
            b"BKT",
            b"Bucket Token",
            b"the utility token of bucketprotocol.io",
            option::some(url::new_unsafe_from_bytes(
                b"https://ipfs.io/ipfs/QmRfNHXUBoeCczQexM2vzYzCM11tyovW1ZmTsb4ZMc1poj"),
            ),
            ctx,
        );

        transfer::public_freeze_object(bkt_metadata);
        let eco_part = coin::mint_balance(&mut bkt_treasury_cap, amount_of(ECO_ALLOCATION));

        transfer::public_transfer(coin::mint(&mut bkt_treasury_cap, amount_of(BKT_TOTAL_SUPPLY - ECO_ALLOCATION), ctx), MULTI_SIG_ADDRESS);

        let bkt_supply = coin::treasury_into_supply(bkt_treasury_cap);
        // std::debug::print(&balance::supply_value(&bkt_supply));
        // std::debug::print(&amount_of(BKT_TOTAL_SUPPLY));
        assert!(balance::supply_value(&bkt_supply) == amount_of(BKT_TOTAL_SUPPLY), 0);
        let bkt_treasury = BktTreasury {
            id: object::new(ctx),
            eco_part,
            bkt_supply,
        };
        let admin_cap = BktAdminCap { id: object::new(ctx) };
        (bkt_treasury, admin_cap)
    }

    public fun collect_bkt(bkt_treasury: &mut BktTreasury, bkt: Balance<BKT>) {
        balance::join(&mut bkt_treasury.eco_part, bkt);
    }

    public fun withdraw_treasury(
        _: &BktAdminCap,
        bkt_treasury: &mut BktTreasury,
        amount: u64,
    ): Balance<BKT> {
        balance::split(&mut bkt_treasury.eco_part, amount)
    }

    entry fun withdraw_treasury_to(
        cap: &BktAdminCap,
        bkt_treasury: &mut BktTreasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let bkt = withdraw_treasury(cap, bkt_treasury, amount);
        transfer::public_transfer(coin::from_balance(bkt, ctx), recipient);
    }

    public(friend) fun release_bkt(bkt_treasury: &mut BktTreasury, amount: u64): Balance<BKT> {
        balance::split(&mut bkt_treasury.eco_part, amount)
    }

    fun amount_of(amount: u64): u64 { amount * 1000 }

    public fun get_eco_part_balance(bkt_treasury: &BktTreasury): u64 {
        balance::value(&bkt_treasury.eco_part)
    }

    #[test_only]
    public fun new_for_testing(witness: BKT, ctx: &mut TxContext): (BktTreasury, BktAdminCap) {
        new_treasury(witness, ctx)
    }

    #[test_only]
    #[lint_allow(share_owned)]
    public fun share_for_testing(witness: BKT, admin: address, ctx: &mut TxContext) {
        let (bkt_treasury, bkt_admin_cap) = new_treasury(witness, ctx);
        transfer::share_object(bkt_treasury);
        transfer::transfer(bkt_admin_cap, admin);
    }

    #[test]
    fun test_init() {
        use std::vector;
        use sui::test_scenario;
        use sui::test_utils;
        use sui::coin::Coin;
        
        let dev = @0xde123;

        let scenario_val =test_scenario::begin(dev);
        let scenario = &mut scenario_val;
        {
            init(test_utils::create_one_time_witness<BKT>(), test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, dev);
        {
            assert!(test_scenario::has_most_recent_shared<BktTreasury>(), 0);
            assert!(vector::length(&test_scenario::ids_for_address<BktAdminCap>(MULTI_SIG_ADDRESS)) == 1, 0);
            let bkt_treasury = test_scenario::take_shared<BktTreasury>(scenario);
            assert!(get_eco_part_balance(&bkt_treasury) == 30_000_000_000, 0);
            test_scenario::return_shared(bkt_treasury);
            let bkt_coin_obj = test_scenario::take_from_address<Coin<BKT>>(scenario, MULTI_SIG_ADDRESS);
            assert!(coin::value(&bkt_coin_obj) == 70_000_000_000, 0);
            test_scenario::return_to_address(MULTI_SIG_ADDRESS, bkt_coin_obj);
        };

        test_scenario::end(scenario_val);
    }
}
