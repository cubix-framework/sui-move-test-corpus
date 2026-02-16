module capability_hero::store;

use sui::balance::{Self, Balance};
use sui::coin::Coin;
use sui::sui::SUI;
use sui::table::{Self, Table};

public struct Armor has copy, drop, store {}
public struct Weapon has copy, drop, store {}

const ENotAuthorized: u64 = 0;
const EEmptyStore: u64 = 1;
const ENotEnoughFunds: u64 = 2;

public struct StoreAdminCap has key {
    id: UID,
    // TODO: add a property to store the store id
}

public fun new_armor(): Armor {
    Armor {}
}

public fun new_weapon(): Weapon {
    Weapon {}
}

public struct HeroStore<phantom T: store> has key, store {
    id: UID,
    items: Table<u64, T>,
    item_price: u64,
    funds: Balance<SUI>,
}

public fun build_store<T: store>(item_price: u64, ctx: &mut TxContext) {
    // TODO: Initialize the store and the associated admin cap
}

public fun add_item<T: store>(store: &mut HeroStore<T>, admin_cap: &StoreAdminCap, item: T) {
    // TODO: add a check to ensure the admin cap is valid
    let items = &mut store.items;
    let len = items.length();
    table::add(items, len, item);
}

public fun collect_funds<T: store>(
    store: &mut HeroStore<T>,
    admin_cap: &StoreAdminCap,
    ctx: &mut TxContext,
): Coin<SUI> {
    // TODO: add a check to ensure the admin cap is valid

    let funds = store.funds.withdraw_all();
    funds.into_coin(ctx)
}

public fun buy_item<T: store>(store: &mut HeroStore<T>, coin: Coin<SUI>): T {
    assert!(coin.value() >= store.item_price, ENotEnoughFunds);
    assert!(!store.items.is_empty(), EEmptyStore);
    store.funds.join(coin.into_balance());
    let items = &mut store.items;
    let len = items.length();
    let item = table::remove(items, len - 1);
    item
}

public fun item_price<T: store>(store: &HeroStore<T>): u64 {
    store.item_price
}
