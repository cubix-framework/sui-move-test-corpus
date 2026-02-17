// Copyright (c) Typus Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(unused)]
module typus::tgld {

    use sui::coin::{TreasuryCap};
    use sui::token::{TokenPolicyCap};

    public struct TGLD has drop {}

    public struct TgldRegistry has key {
        id: UID,
        treasury_cap: TreasuryCap<TGLD>,
        token_policy_cap: TokenPolicyCap<TGLD>,
    }
}