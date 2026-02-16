module bag_hero::hero;

use std::string::String;
use sui::bag::{Self, Bag};

public struct Fire has copy, drop, store ()
public struct Water has copy, drop, store ()
public struct Earth has copy, drop, store ()
public struct Air has copy, drop, store ()


public struct Hero has key {
    id: UID,
    name: String,
    attributes: Bag,
}

/// @dev Creates a new hero with a given name and default attributes.
/// @param name The name of the hero.
/// @param ctx The transaction context.
/// @return A new hero with a given name and default attributes.
public fun create_hero(name: String, ctx: &mut TxContext): Hero {
    // create a hero with a bag of attributes with default values

}

public fun increase_fire_attribute(hero: &mut Hero, amount: u16) {
    // update the fire attribute
}

// create the other increase functions

public fun get_fire_attribute(hero: &Hero): u16 {
    // get the fire attribute value
}

// create the other get functions

public fun transfer_hero(hero: Hero, to: address) {
    transfer::transfer(hero, to);
}

// Test Only

#[test_only]
use sui::test_utils::{assert_eq, destroy};

#[test]
public fun test_create_hero_and_increase_attributes() {
    let mut hero = create_hero(b"Hero".to_string(), &mut tx_context::dummy());

    assert_eq(hero.attributes.length(), 4);

    assert_eq(hero.attributes.contains_with_type<Fire, u16>(Fire()), true);
    assert_eq(hero.attributes.contains_with_type<Water, u16>(Water()), true);
    assert_eq(hero.attributes.contains_with_type<Earth, u16>(Earth()), true);
    assert_eq(hero.attributes.contains_with_type<Air, u16>(Air()), true);

    assert_eq(get_fire_attribute(&hero), 0);
    assert_eq(get_water_attribute(&hero), 0);
    assert_eq(get_earth_attribute(&hero), 0);
    assert_eq(get_air_attribute(&hero), 0);

    increase_fire_attribute(&mut hero, 10);
    increase_water_attribute(&mut hero, 20);
    increase_earth_attribute(&mut hero, 30);
    increase_air_attribute(&mut hero, 40);

    assert_eq(get_fire_attribute(&hero), 10);
    assert_eq(get_water_attribute(&hero), 20);
    assert_eq(get_earth_attribute(&hero), 30);
    assert_eq(get_air_attribute(&hero), 40);

    destroy(hero);
}