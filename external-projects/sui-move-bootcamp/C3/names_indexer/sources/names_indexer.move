module names_indexer::names_indexer;

use std::string::String;
use sui::table::{Self, Table};

public struct NameIndexer has key {
    id: UID,
    names: Table<vector<u8>, String>,
}

fun init(ctx: &mut TxContext) {
    let mut names_indexer = table::new<vector<u8>, String>(ctx);
    names_indexer.add(b"nikos", b"Nikos".to_string());
    names_indexer.add(b"teo", b"Teo".to_string());
    names_indexer.add(b"john", b"John".to_string());
    names_indexer.add(b"maria", b"Maria".to_string());
    transfer::share_object(NameIndexer {
        id: object::new(ctx),
        names: names_indexer,
    });
}

public fun borrow_name(self: &NameIndexer, name: vector<u8>): String {
    *self.names.borrow(name)
}
