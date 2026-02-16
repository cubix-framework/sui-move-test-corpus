#[test_only]
module MyToken::my_token_tests {
    use 0x1::signer;
    use 0x1::vector;
    use MyToken::coin;

    // простой «синк», чтобы не дропать ресурс coin::Coin
    struct Trash has key { inner: vector<coin::Coin> }

    public entry fun init_trash(acc: &signer) {
        move_to(acc, Trash { inner: vector::empty<coin::Coin>() });
    }

    fun sink(acc: &signer, c: coin::Coin) acquires Trash {
        let t = borrow_global_mut<Trash>(signer::address_of(acc));
        vector::push_back(&mut t.inner, c);
    }

    // позитив: один mint
    #[test(admin = @0xA)]
    public entry fun test_mint_balance_ok(admin: &signer) acquires Trash {
        init_trash(admin);
        let c = coin::mint(100);
        assert!(coin::balance(&c) == 100, 0);
        sink(admin, c);
    }

    // позитив: два mint’а, проверяем оба баланса отдельно
    #[test(admin = @0xB)]
    public entry fun test_double_mint_ok(admin: &signer) acquires Trash {
        init_trash(admin);
        let c1 = coin::mint(60);
        let c2 = coin::mint(250);
        assert!(coin::balance(&c1) == 60, 0);
        assert!(coin::balance(&c2) == 250, 1);
        sink(admin, c1);
        sink(admin, c2);
    }
}
