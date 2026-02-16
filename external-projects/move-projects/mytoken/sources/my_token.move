module MyToken::coin {
    /// Minimal in-memory coin (no std imports)
    struct Coin has store { value: u64 }

    const EINSUFFICIENT_BALANCE: u64 = 1;

    /// Mint new tokens
    public fun mint(amount: u64): Coin {
        Coin { value: amount }
    }

    /// Read balance
    public fun balance(c: &Coin): u64 { c.value }

    /// Split amount from coin into a new coin
    public fun transfer(from: &mut Coin, amount: u64): Coin {
        assert!(from.value >= amount, EINSUFFICIENT_BALANCE);
        from.value = from.value - amount;
        Coin { value: amount }
    }

    /// Burn coin and return amount
public fun burn(c: Coin): u64 {
    let Coin { value: v } = c;
    v
}
public entry fun entry_demo(_sender: &signer) {
    let c = mint(100);
    let part = transfer(&mut c, 40);
    let burned_part = burn(part);
    let burned_rest = burn(c);
    assert!(burned_part + burned_rest == 100, 0);
}

}
