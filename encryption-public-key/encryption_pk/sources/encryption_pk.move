// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
module encryption_pk::encryption_pk {
    use std::string::String;
    use sui::group_ops::Element;
    use sui::bls12381::{Self, G1};

    public struct UserEncryptionPublicKey has key, store {
        id: UID,
        pk: Element<G1>, // A valid G1 element that represents the public key for the encryption key. 
        description: String // A string that stores additional information about the encryption key. 
    }

    public fun create_encryption_pk(pk: vector<u8>, description: String, ctx: &mut TxContext) {
        transfer::public_transfer(
            UserEncryptionPublicKey {
                id: object::new(ctx),
                pk: bls12381::g1_from_bytes(&pk),
                description: description
            },
            tx_context::sender(ctx)
        )
    }
}

