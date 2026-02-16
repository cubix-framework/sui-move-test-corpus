module hero::blacksmith;

public struct Sword has key, store {
    id: UID,
    attack: u64,
}

public fun new_sword(attack: u64, ctx: &mut TxContext): Sword {
    Sword {
        id: object::new(ctx),
        attack
    }
}

public fun attack(self: &Sword): u64 {
    self.attack
}
