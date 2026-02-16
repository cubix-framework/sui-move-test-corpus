module Escrow::escrow {
    /// Error codes
    const E_ALREADY_FUNDED: u64 = 1;
    const E_NOT_FUNDED: u64   = 2;
    const E_COMPLETED: u64    = 3;
    const E_INSUFFICIENT: u64 = 4;
    const E_NOT_BUYER: u64    = 5;
    const E_NOT_SELLER: u64   = 6;

    /// Simple wallet (no global storage)
    struct Wallet has store { balance: u64 }

    /// Deal state (in-memory demo)
    struct Deal has store {
        buyer: address,
        seller: address,
        amount: u64,
        funded: bool,
        completed: bool,
    }

    public fun new_wallet(): Wallet { Wallet { balance: 0 } }

    public fun deposit(w: &mut Wallet, amount: u64) { w.balance = w.balance + amount; }

    public fun balance(w: &Wallet): u64 { w.balance }

    public fun create(buyer: address, seller: address, amount: u64): Deal {
        Deal { buyer, seller, amount, funded: false, completed: false }
    }

    public fun fund(buyer: address, bw: &mut Wallet, d: &mut Deal) {
        assert!(buyer == d.buyer, E_NOT_BUYER);
        assert!(!d.funded, E_ALREADY_FUNDED);
        assert!(bw.balance >= d.amount, E_INSUFFICIENT);
        bw.balance = bw.balance - d.amount;
        d.funded = true;
    }

    public fun release(seller: address, sw: &mut Wallet, d: &mut Deal) {
        assert!(seller == d.seller, E_NOT_SELLER);
        assert!(d.funded, E_NOT_FUNDED);
        assert!(!d.completed, E_COMPLETED);
        sw.balance = sw.balance + d.amount;
        d.completed = true;
    }

    public fun refund(buyer: address, bw: &mut Wallet, d: &mut Deal) {
        assert!(buyer == d.buyer, E_NOT_BUYER);
        assert!(d.funded, E_NOT_FUNDED);
        assert!(!d.completed, E_COMPLETED);
        bw.balance = bw.balance + d.amount;
        d.completed = true;
    }

    /// Внутренние “пожиратели” ресурсов (чтобы избежать implicit drop)
    fun destroy_wallet(w: Wallet) {
        let Wallet { balance: _ } = w;
    }
    fun destroy_deal(d: Deal) {
        let Deal { buyer: _, seller: _, amount: _, funded: _, completed: _ } = d;
    }

     // Публичные обёртки для юнит-тестов
     #[test_only]
     public fun destroy_wallet_for_test(w: Wallet) { destroy_wallet(w); }

     #[test_only]
     public fun destroy_deal_for_test(d: Deal) { destroy_deal(d); }

     /// DEMO entry: депозит → фандинг → релиз
        public entry fun entry_demo(_s: &signer) {
        let bw = new_wallet();
        let sw = new_wallet();

        deposit(&mut bw, 150);
        let d = create(@0x1, @0x2, 100);

        fund(@0x1, &mut bw, &mut d);
        release(@0x2, &mut sw, &mut d);

        assert!(balance(&bw) == 50, 0);
        assert!(balance(&sw) == 100, 1);

        // Потребляем ресурсы
        destroy_deal(d);
        destroy_wallet(bw);
        destroy_wallet(sw);
    }
}
