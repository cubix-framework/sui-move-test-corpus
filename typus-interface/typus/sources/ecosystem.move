// Copyright (c) Typus Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(unused)]
module typus::ecosystem {

    use sui::vec_set::{VecSet};
    use std::type_name::{TypeName};

    public struct Version has key {
        id: UID,
        value: u64,
        fee_pool: FeePool,
        authority: VecSet<address>,
        u64_padding: vector<u64>,
    }

    public struct FeePool has key, store {
        id: UID,
        fee_infos: vector<FeeInfo>,
    }

    public struct FeeInfo has copy, drop, store {
        token: TypeName,
        value: u64,
    }
}