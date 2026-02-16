module hero::hero;

use std::string::String;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::event;
use sui::sui::SUI;

const EHeroFeeTooLow: u64 = 1;

const HERO_MINT_FEE: u64 = 100_000_000;

public struct FeeCap has key {
    id: UID,
}

public struct Treasury has key {
    id: UID,
    balance_fees: Balance<SUI>,
}

public struct Hero has key {
    id: UID,
    name: String,
}

public struct HeroEvent has copy, drop, store {
    hero_id: ID,
    hero_name: String,
    owner: address,
    timestamp: u64,
}

public struct TakeFeesEvent has copy, drop, store {
    treasury_id: ID,
    amount: u64,
    admin: address,
    timestamp: u64,
}

fun init(ctx: &mut TxContext) {
    let treasury = Treasury {
        id: object::new(ctx),
        balance_fees: balance::zero(),
    };

    let fee_cap = FeeCap {
        id: object::new(ctx),
    };

    transfer::share_object(treasury);
    transfer::transfer(fee_cap, ctx.sender());
}

public fun mint_hero(
    name: String,
    fee_coin: Coin<SUI>,
    treasury: &mut Treasury,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(fee_coin.value() >= HERO_MINT_FEE, EHeroFeeTooLow);

    treasury.balance_fees.join(fee_coin.into_balance());

    let hero = Hero {
        id: object::new(ctx),
        name,
    };

    let event = HeroEvent {
        hero_id: hero.id.uid_to_inner(),
        hero_name: hero.name,
        owner: ctx.sender(),
        timestamp: clock.timestamp_ms(),
    };

    transfer::transfer(hero, ctx.sender());
    event::emit(event);
}

entry fun take_fees(
    _fee_cap: &FeeCap,
    treasury: &mut Treasury,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let event = TakeFeesEvent {
        treasury_id: treasury.id.uid_to_inner(),
        amount: treasury.balance_fees.value(),
        admin: ctx.sender(),
        timestamp: clock.timestamp_ms(),
    };

    let coin = treasury.balance_fees.withdraw_all().into_coin(ctx);
    transfer::public_transfer(coin, ctx.sender());
    event::emit(event);
}
