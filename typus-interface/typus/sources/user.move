// Copyright (c) Typus Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(unused)]
module typus::user {
    use sui::linked_table::{LinkedTable};

    public struct TypusUserRegistry has key {
        id: UID,
        metadata: LinkedTable<address, Metadata>,
    }

    public struct Metadata has store, drop {
        content: vector<u64>,
    }
}