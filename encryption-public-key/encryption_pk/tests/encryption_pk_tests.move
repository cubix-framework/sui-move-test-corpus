// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[test_only]
module encryption_pk::encryption_pk_tests {
    use encryption_pk::encryption_pk::create_encryption_pk;
    use sui::test_scenario::Self;
    use std::string::utf8;
    use sui::group_ops;

    #[test]
    fun test_encryption_pk() {
        let alice: address = @0xAAAA;
        let mut test = test_scenario::begin(alice);
        test_scenario::next_tx(&mut test, alice);
        {
            create_encryption_pk(x"b58cfc3b0f43d98e7dbe865af692577d52813cb62ef3c355215ec3be2a0355a1ae5da76dd3e626f8a60de1f4a8138dee", utf8(b"encryption key for x marketplace"), test_scenario::ctx(&mut test));
        };
        test_scenario::end(test);
    }


    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_encryption_pk_invalid() {
        let alice: address = @0xAAAA;
        let mut test = test_scenario::begin(alice);
        test_scenario::next_tx(&mut test, alice);
        {
            create_encryption_pk(x"0000", utf8(b"test"), test_scenario::ctx(&mut test));
        };
        test_scenario::end(test);
    }
}
