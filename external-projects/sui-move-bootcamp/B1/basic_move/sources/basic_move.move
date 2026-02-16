module basic_move::basic_move;
public struct Hero has key, store {
    id: object::UID,
}

public struct InsignificantWeapon has drop, store {
    power: u8,
}

public fun mint_hero(ctx: &mut TxContext): Hero {
    let hero = Hero { id: object::new(ctx) };
    hero
}

public fun create_insignificant_weapon(power: u8): InsignificantWeapon {
    InsignificantWeapon { power }
}

#[test]
fun test_mint() {}

#[test]
fun test_drop_semantics() {}
