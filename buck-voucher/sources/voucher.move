module buck_voucher::boucher {

    use std::string::utf8;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::package;
    use sui::display;
    use sui::event;
    use bucket_protocol::buck::BUCK;

    // ----------- OTW -----------

    struct BOUCHER has drop {}

    // ----------- Objects -----------

    struct Boucher has key, store {
        id: UID,
        value: u64,
    }

    struct Treasury has key {
        id: UID,
        balance: Balance<BUCK>,
    }

    struct MintCap has key, store {
        id: UID,
    }

    // ----------- Events -----------

    struct MintEvent has copy, drop {
        boucher_id: ID,
        value: u64,
    }

    struct RedeemEvent has copy, drop {
        boucher_id: ID,
        value: u64,
    }

    struct DepositEvent has copy, drop {
        fund_amount: u64,
    }

    // ----------- Constructor -----------

    fun init(otw: BOUCHER, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"BUCK Voucher"),
            utf8(b"https://ipfs.io/ipfs/QmWDTiFbLwqX2ajAjDvqxhMhWGVjVbzi6mn2ufXVM8kM6i"),
            utf8(b"Go https://app.bucketprotocol.io/basecamp to get some $BUCK and enjoy the Bucket ecosystem!"),
            utf8(b"https://app.bucketprotocol.io/basecamp"),
            utf8(b"Bucket Protocol"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Boucher>(
            &publisher, keys, values, ctx
        );
        display::update_version(&mut display);

        let mint_cap = MintCap { id: object::new(ctx) };

        let deployer = tx_context::sender(ctx);
        transfer::public_transfer(publisher, deployer);
        transfer::public_transfer(display, deployer);
        transfer::public_transfer(mint_cap, deployer);
        transfer::share_object(Treasury {
            id: object::new(ctx),
            balance: balance::zero(),
        });
    }

    public fun mint(
        _cap: &MintCap,
        value: u64,
        ctx: &mut TxContext,
    ): Boucher {
        let boucher = Boucher {
            id: object::new(ctx),
            value,
        };
        let boucher_id = object::id(&boucher);
        event::emit(MintEvent { boucher_id, value });
        boucher
    }

    public fun redeem(
        treasury: &mut Treasury,
        boucher: Boucher,
        ctx: &mut TxContext,
    ): Coin<BUCK> {
        let boucher_id = object::id(&boucher);
        let Boucher { id, value } = boucher;
        object::delete(id);
        event::emit(RedeemEvent { boucher_id, value });
        coin::take(&mut treasury.balance, value, ctx)
    }

    public fun deposit(
        treasury: &mut Treasury,
        fund: Coin<BUCK>,
    ) {
        let fund_amount = coin::value(&fund);
        event::emit(DepositEvent { fund_amount });
        coin::put(&mut treasury.balance, fund);
    }

    public fun batch_mint_to(
        cap: &MintCap,
        value: u64,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let counter = 0;
        while (counter < amount) {
            let boucher = mint(cap, value, ctx);
            transfer::transfer(boucher, recipient);
            counter = counter + 1;
        };
    }
}