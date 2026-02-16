#[test_only]
module PaySplit::split_tests {
    use 0x1::signer;
    use PaySplit::split;

    // === 1) Точное распределение без остатка ===
    // shares: 50/30/20; deposit: 100 -> A=50, B=30, C=20, fees=0
    #[test(admin=@0xAA, a=@0xA, b=@0xB, c=@0xC)]
    public entry fun test_exact_split_ok(
        admin: &signer, a: &signer, b: &signer, c: &signer
    ) {
        let rcpts = vector[signer::address_of(a), signer::address_of(b), signer::address_of(c)];
        let shares = vector[50, 30, 20];
        split::init(admin, rcpts, shares);

        let admin_addr = signer::address_of(admin);
        split::deposit(admin, admin_addr, 100);

        assert!(split::view_balance(admin_addr, signer::address_of(a)) == 50, 0);
        assert!(split::view_balance(admin_addr, signer::address_of(b)) == 30, 1);
        assert!(split::view_balance(admin_addr, signer::address_of(c)) == 20, 2);
    }

    // === 2) Остаток идёт в fees, затем админ забирает ===
    // shares: 1/1; deposit: 1 -> parts=0/0, remainder=1 -> fees=1 -> withdraw_fees => admin=1
    #[test(admin=@0xAB, a=@0xD, b=@0xE)]
    public entry fun test_remainder_goes_to_admin_ok(
        admin: &signer, a: &signer, b: &signer
    ) {
        let rcpts = vector[signer::address_of(a), signer::address_of(b)];
        let shares = vector[1, 1];
        split::init(admin, rcpts, shares);

        let admin_addr = signer::address_of(admin);
        split::deposit(admin, admin_addr, 1);         // remainder = 1
        split::withdraw_fees(admin, admin_addr);       // move fees -> admin balance

        assert!(split::view_balance(admin_addr, admin_addr) == 1, 10);
    }

    // === 3) Негатив: только админ может withdraw_fees (E_NOT_ADMIN = 4) ===
    #[test(admin=@0xAC, bad=@0xEF, a=@0x1, b=@0x2)]
    #[expected_failure(abort_code = 4, location = PaySplit::split)]
    public entry fun test_withdraw_fees_only_admin_fails(
        admin: &signer, bad: &signer, a: &signer, b: &signer
    ) {
        let rcpts = vector[signer::address_of(a), signer::address_of(b)];
        let shares = vector[1, 1];
        split::init(admin, rcpts, shares);

        let admin_addr = signer::address_of(admin);
        // не-админ вызывает — должно упасть с кодом 4
        split::withdraw_fees(bad, admin_addr);
    }
}
