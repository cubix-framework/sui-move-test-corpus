#[test_only]
module scenario::xp_tome_tests;

use sui::test_scenario;

use scenario::acl;

#[test]
fun test_new_xp_tome() {
    let admin = @0x11111;
    let hero_owner = @0x22222;
    let health = 20;
    let stamina = 5;

    // Initialize package
    let mut scenario = test_scenario::begin(admin);
    acl::init_for_testing(scenario.ctx());

    // Task: Create new `XPTome`
    {

    };

    // Task: Check `XPTome`'s field values
    {

    };

    scenario.end();
}

