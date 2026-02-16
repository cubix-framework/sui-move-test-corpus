#[test_only]
module SimpleNFT::simple_nft_tests {
    use SimpleNFT::nft;

    const A1: address = @0x1;
    const A2: address = @0x2;

    // позитив: mint #0 → transfer → owner проверка
    #[test]
    public entry fun test_mint_transfer_ok() {
        let r = nft::new_registry();
        nft::mint(&mut r, A1, b"Test NFT");
        assert!(nft::get_owner(&r, 0) == A1, 0);

        nft::transfer(&mut r, 0, A2);
        assert!(nft::get_owner(&r, 0) == A2, 1);

        nft::destroy_registry_for_test(r);
    }

    // негатив: неверный id при get_owner → abort(5) в SimpleNFT::nft
    #[test]
    #[expected_failure(abort_code = 5, location = SimpleNFT::nft)]
    public entry fun test_get_owner_wrong_id_fails() {
        let r = nft::new_registry();
        nft::mint(&mut r, A1, b"x");
        let _ = nft::get_owner(&r, /*wrong*/ 123);
        nft::destroy_registry_for_test(r);
    }
}
