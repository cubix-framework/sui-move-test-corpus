/// Module: signature
/// A module implementing signature-based authorization.
/// This module uses Ed25519 signatures to verify and authorize privileged operations.
module admin_action::signature;

use sui::{ed25519, hash, package};

/// Error code indicating the first mint attempt failed.
const ECouldNotMintFirst: u64 = 0;
/// Error code indicating the second mint attempt failed (replay attack).
const ECouldNotMintSecond: u64 = 1;
/// Error code indicating that the test was expected to fail earlier.
const EExpectedFailure: u64 = 2;

// Setup Task 1: Change with your public key
/// The public key used to verify signatures for minting operations.
const BE_PUBLIC_KEY: vector<u8> = x"ccfce9e209216138d29318da27f6c1b42ec863962ab7d9b56d9f6e22ccb31b86";

/// A one-time witness type used for module initialization.
public struct SIGNATURE() has drop;

/// A counter used to prevent replay attacks.
/// The counter value is included in the signed message for each mint operation.
public struct Counter has key {
    id: UID,
    value: u64,
}

/// A Hero NFT representing a character with health and stamina attributes.
/// This is a transferable asset that can be minted by authorized signers.
public struct Hero has key {
    id: UID,
    health: u64,
    stamina: u64,
}

/// Initializes the signature module.
/// Creates a new Counter object initialized to zero.
/// The counter is shared with all users but only valid signatures can perform privileged actions.
fun init(otw: SIGNATURE, ctx: &mut TxContext) {
    package::claim_and_keep(otw,ctx);
    transfer::share_object(Counter {
        id: object::new(ctx),
        value: 0
    });
}

/// Mints a new Hero NFT using signature-based authorization.
/// Verifies the provided signature against a message containing:
/// - The sender's address
/// - The health and stamina values
/// Returns true if the mint was successful, false if the signature verification failed.
#[allow(implicit_const_copy)]
public fun mint(
    sig: vector<u8>,
    health: u64,
    stamina: u64,
    ctx: &mut TxContext
): bool {
    // Task 2: Disable replay attacks by using `Counter`.
    let mut msg = b"Mint Hero for: 0x".to_string();
        msg.append(ctx.sender().to_string());
        msg.append_utf8(b";health=");
        msg.append(health.to_string());
        msg.append_utf8(b";stamina=");
        msg.append(stamina.to_string());
    let bytes = msg.into_bytes();
    let digest = hash::blake2b256(&bytes);
    // std::debug::print(&digest);
    // Here we could abort but for testing purposes we just return false.
    if (!ed25519::ed25519_verify(&sig, &BE_PUBLIC_KEY, &digest)) {
        return false
    };

    transfer::transfer(Hero {
        id: object::new(ctx),
        health,
        stamina
    }, ctx.sender());
    return true
}

/// Tests the replay attack prevention mechanism.
/// Attempts to mint a Hero twice with the same signature.
/// The first mint should succeed, but the second should fail due to the counter increment.
#[test]
#[expected_failure(abort_code=ECouldNotMintSecond)]
fun test_replay() {
    let mut ctx = tx_context::new_from_hint(@0x11111, 0, 0, 0, 0);
    // Setup Task 1: Change with your signature generated with create-signature/sign.ts
    let sig = x"5dadee914391b3be7c9587952005c079f33bd26d6a4a1fbe208ed05929b828c468cfdd7e68226168a15143b91e63189614d95e621f3d2388aa523b866e3bdc0c";

    // Task 2: Create a Counter and update below function calls to match the new function signature.
    // let counter = Counter {

    // Since `ctx` is deterministically derived from a fixed hint, the generated
    // `id` will be identical across all runs.
    // std::debug::print(&object::id(&counter));

    assert!(mint(
        sig,
        10,
        10,
        &mut ctx
    ), ECouldNotMintFirst);

    assert!(mint(
        sig,
        10,
        10,
        &mut ctx
    ), ECouldNotMintSecond);

    abort(EExpectedFailure)
}

