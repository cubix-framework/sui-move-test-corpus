/// Module: armory
module armory::armory;

// const EUnclaimedStorageRebate: u64 = 0;
const ETodo: u64 = 0xff;

public struct Sword has key, store {
    id: UID,
    attack: u64
}

// Task 2: Resolve max object size limit
public struct Armory has key, store {
    id: UID,
    swords: vector<ID>,
}

public fun new_armory(ctx: &mut TxContext): Armory {
    // Task 2: Resolve max object size limit
    Armory {
        id: object::new(ctx),
        swords: vector[],
    }
}

#[allow(lint(self_transfer))]
public fun mint_swords(self: &mut Armory, n_swords: u64, attack: u64, ctx: &mut TxContext) {
    // Task 2: Resolve max object size limit
    n_swords.do!(|_i| {
        let sword = Sword {
            id: object::new(ctx),
            attack
        };
        self.swords.push_back(object::id(&sword));
        transfer::public_transfer(sword, ctx.sender());
    });
}

// Aborts if a sword in the range is already destroyed
public fun destroy_sword_entries(_self: &mut Armory, _start_index: u64, _end_index: u64) {
    // Task 4: Claim storage rebate before droping swords table.
    abort(ETodo)
}

public fun destroy(self: Armory) {
    // Task 2: Resolve max object size limit
    let Armory {
        id,
        ..
    } = self;
    id.delete();
}
