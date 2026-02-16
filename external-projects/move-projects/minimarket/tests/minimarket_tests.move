#[test_only]
module minimarket::minimarket_tests {
    use 0x1::signer;
    use minimarket::minimarket;

    // позитив: init → list → buy → withdraw_fees
    #[test(s = @0xC)]
    public entry fun test_list_buy_withdraw(s: &signer) {
        let a = signer::address_of(s);
        minimarket::init(s, 1000);            // 10% комиссия
        minimarket::list(s, a, 0, 10_000);    // новый лот
        minimarket::buy(s, a, 0, 10_000);     // покупка
        minimarket::withdraw_fees(s, a);      // админ = продавец
        let bal = minimarket::view_balance(a, a);
        assert!(bal == 10_000, 0);
    }

    // негатив: повторный init должен падать (E_ALREADY_INITIALIZED = 1)
    #[test(admin = @0xD)]
    #[expected_failure(abort_code = 1, location = minimarket::minimarket)]
    public entry fun test_init_twice_fails(admin: &signer) {
        minimarket::init(admin, 250);
        minimarket::init(admin, 250);
    }
}
