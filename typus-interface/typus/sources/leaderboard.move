// Copyright (c) Typus Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(unused)]
module typus::leaderboard {

    public struct TypusLeaderboardRegistry has key {
        id: UID,
        active_leaderboard_registry: UID,
        inactive_leaderboard_registry: UID,
    }
}