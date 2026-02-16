/// Module: sword
module sword::sword;

use std::string::String;

use sui::display;
use sui::package::{Self, Publisher};

const EInvalidPublisher: u64 = 0;

public struct SWORD() has drop;

public struct Sword has key, store {
    id: UID,
    name: String,
    damage: u32,
    effects: vector<String>
}

fun init(otw: SWORD, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);
    let keys = vector[
        b"name".to_string(),
        b"image_url".to_string(),
        b"description".to_string(),
    ];
    let values = vector[
        b"{name}".to_string(),
        b"https://aggregator.walrus-testnet.walrus.space/v1/blobs/VlcqzSTnZDNBgB_7R52DPTbXlX-mCyv7j8yDkHGU1YI".to_string(),
        b"Sword of {damage} damage and effects:\n{effects}".to_string(),
    ];
    let mut display = display::new_with_fields<Sword>(
        &publisher, keys, values, ctx
    );
    display.update_version();

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
}

public fun new(
    pub: &Publisher,
    name: String,
    damage: u32,
    effects: vector<String>,
    ctx: &mut TxContext,
): Sword {
    assert!(pub.from_package<SWORD>(), EInvalidPublisher);
    Sword {
        id: object::new(ctx),
        name,
        damage,
        effects,
    }
}

public fun burn(self: Sword) {
    let Sword { id, .. } = self;
    id.delete();
}

