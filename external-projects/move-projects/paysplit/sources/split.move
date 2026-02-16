module PaySplit::split {
    use std::signer;
    use std::vector;

    const E_ALREADY_INIT: u64 = 1;
    const E_EMPTY: u64 = 2;
    const E_LEN_MISMATCH: u64 = 3;
    const E_NOT_ADMIN: u64 = 4;

    struct Balance has drop, store {
        owner: address,
        amount: u64,
    }

    struct Splitter has key {
        admin: address,
        recipients: vector<address>,
        shares: vector<u64>,
        total_shares: u64,
        balances: vector<Balance>,
        fees_accumulated: u64,
    }

    /// one-time init under admin
    public entry fun init(admin: &signer, recipients: vector<address>, shares: vector<u64>) {
        let admin_addr = signer::address_of(admin);
        assert!(!exists<Splitter>(admin_addr), E_ALREADY_INIT);

        let n1 = vector::length(&recipients);
        let n2 = vector::length(&shares);
        assert!(n1 > 0, E_EMPTY);
        assert!(n1 == n2, E_LEN_MISMATCH);

        let i = 0u64;
        let total = 0u64;
        while (i < n2) {
            total = total + *vector::borrow(&shares, i);
            i = i + 1;
        };

        move_to(admin, Splitter {
            admin: admin_addr,
            recipients,
            shares,
            total_shares: total,
            balances: vector::empty<Balance>(),
            fees_accumulated: 0,
        });
    }

    fun find_balance_index(bals: &vector<Balance>, owner: address): (bool, u64) {
        let i = 0u64;
        let n = vector::length(bals);
        while (i < n) {
            let b = vector::borrow(bals, i);
            if (b.owner == owner) return (true, i);
            i = i + 1;
        };
        (false, 0)
    }

    fun credit_balance(bals: &mut vector<Balance>, owner: address, amt: u64) {
        let (found, idx) = find_balance_index(bals, owner);
        if (found) {
            let b = vector::borrow_mut(bals, idx);
            b.amount = b.amount + amt;
        } else {
            vector::push_back(bals, Balance { owner, amount: amt });
        }
    }

    /// deposit amount → split by shares; integer remainder goes to fees_accumulated
    public entry fun deposit(_payer: &signer, admin_addr: address, amount: u64) acquires Splitter {
        let s = borrow_global_mut<Splitter>(admin_addr);
        let n = vector::length(&s.recipients);

        let i = 0u64;
        let distributed = 0u64;
        while (i < n) {
            let who = *vector::borrow(&s.recipients, i);
            let sh  = *vector::borrow(&s.shares, i);
            let part = (amount * sh) / s.total_shares;
            if (part > 0) credit_balance(&mut s.balances, who, part);
            distributed = distributed + part;
            i = i + 1;
        };

        let rem = amount - distributed;
        s.fees_accumulated = s.fees_accumulated + rem;
    }

    /// recipient withdraws their pending balance to zero (internal accounting)
    public entry fun withdraw(rcpt: &signer, admin_addr: address) acquires Splitter {
        let caller = signer::address_of(rcpt);
        let s = borrow_global_mut<Splitter>(admin_addr);

        let (found, idx) = find_balance_index(&s.balances, caller);
        if (found) {
            let b = vector::borrow_mut(&mut s.balances, idx);
            b.amount = 0;
        }
    }

    /// admin converts accumulated fees into own balance
    public entry fun withdraw_fees(admin: &signer, admin_addr: address) acquires Splitter {
        let caller = signer::address_of(admin);
        let s = borrow_global_mut<Splitter>(admin_addr);
        assert!(s.admin == caller, E_NOT_ADMIN);

        let f = s.fees_accumulated;
        if (f > 0) {
            s.fees_accumulated = 0;
            credit_balance(&mut s.balances, caller, f);
        }
    }

    /// view pending balance for `owner`
    public fun view_balance(admin_addr: address, owner: address): u64 acquires Splitter {
        let s = borrow_global<Splitter>(admin_addr);
        let (found, idx) = find_balance_index(&s.balances, owner);
        if (!found) {
            0
        } else {
            let b = vector::borrow(&s.balances, idx);
            b.amount
        }
    }
}
