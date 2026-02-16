module Vesting::vesting {
    use std::signer;
    use std::vector;

    // --- Ошибки ---
    const E_ALREADY_INIT: u64      = 1;
    const E_NOT_INIT: u64          = 2;
    const E_BAD_TIME: u64          = 3;
    const E_NOT_BENEFICIARY: u64   = 4;
    const E_BAD_ID: u64            = 5;
    const E_NOTHING_TO_CLAIM: u64  = 6;

    // --- Модель данных ---
    struct Schedule has store {
        beneficiary: address,
        total: u64,
        start: u64,
        end: u64,
        claimed: u64,
    }

    struct Balance has drop, store { owner: address, amount: u64 }

    struct State has key {
        admin: address,
        schedules: vector<Schedule>,
        balances: vector<Balance>,
        initialized: bool,
    }

    // --- Внутренние утилиты ---
    fun is_inited(addr: address): bool { exists<State>(addr) }

    fun assert_inited(addr: address) {
        assert!(exists<State>(addr), E_NOT_INIT);
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

    fun credit_balance(bals: &mut vector<Balance>, owner: address, amount: u64) {
        let (found, idx) = find_balance_index(bals, owner);
        if (found) {
            let b = vector::borrow_mut(bals, idx);
            b.amount = b.amount + amount;
        } else {
            vector::push_back(bals, Balance { owner, amount });
        }
    }

    fun vested_at(s: &Schedule, now: u64): u64 {
        if (now <= s.start) {
            0
        } else if (now >= s.end) {
            s.total
        } else {
            // линейная разблокировка
            let elapsed = now - s.start;
            let dur = s.end - s.start;
            (s.total * elapsed) / dur
        }
    }

    fun claimable_at(s: &Schedule, now: u64): u64 {
        let v = vested_at(s, now);
        if (v <= s.claimed) 0 else v - s.claimed
    }

    // --- Публичное API ---

    /// Разворачивает состояние под адресом администратора
    public entry fun init(admin: &signer) {
        let a = signer::address_of(admin);
        assert!(!is_inited(a), E_ALREADY_INIT);
        move_to(admin, State {
            admin: a,
            schedules: vector::empty<Schedule>(),
            balances: vector::empty<Balance>(),
            initialized: true,
        });
    }

    /// Создаёт новую вестинг-выплату.
    /// Требования: end > start, total > 0, init уже вызван.
    public entry fun create(admin: &signer, beneficiary: address, total: u64, start: u64, end: u64) acquires State {
        let a = signer::address_of(admin);
        assert_inited(a);
        assert!(end > start && total > 0, E_BAD_TIME);

        let st = borrow_global_mut<State>(a);
        vector::push_back(&mut st.schedules, Schedule {
            beneficiary,
            total,
            start,
            end,
            claimed: 0,
        });
    }

    /// Бенефициар клеймит доступную на момент `now` сумму.
    public entry fun claim(ben: &signer, admin_addr: address, sched_id: u64, now: u64) acquires State {
        assert_inited(admin_addr);
        let st = borrow_global_mut<State>(admin_addr);

        let n = vector::length(&st.schedules);
        assert!(sched_id < n, E_BAD_ID);

        let s = vector::borrow_mut(&mut st.schedules, sched_id);
        let caller = signer::address_of(ben);
        assert!(caller == s.beneficiary, E_NOT_BENEFICIARY);

        let amt = claimable_at(s, now);
        assert!(amt > 0, E_NOTHING_TO_CLAIM);

        s.claimed = s.claimed + amt;
        credit_balance(&mut st.balances, caller, amt);
    }

    /// Просмотр внутреннего баланса бенефициара (накопленные клеймы)
    public fun view_balance(admin_addr: address, owner: address): u64 acquires State {
        let st = borrow_global<State>(admin_addr);
        let (found, idx) = find_balance_index(&st.balances, owner);
        if (!found) { 0 } else { vector::borrow(&st.balances, idx).amount }
    }

    /// Хелпер для тест-демо: создаёт 1 расписание и делает 3 клейма
    public entry fun entry_demo(admin: &signer) acquires State {
        use std::signer;
        let a = signer::address_of(admin);

        init(admin);
        create(admin, a, 100, /*start*/ 0, /*end*/ 100);

        // клейм на t=30 (30%), затем t=80 (+50), затем t=200 (+20 = всё)
        claim(admin, a, 0, 30);
        claim(admin, a, 0, 80);
        claim(admin, a, 0, 200);

        let bal = view_balance(a, a);
        assert!(bal == 100, 0);
    }
}
