module SimpleNFT::nft {
    /// Простейшая демо-модель без ресурсов внутри полей:
    /// вместо хранения NFT как ресурса, храним его данные в примитивах.
    struct Registry has store {
        next_id: u64,
        has0: bool,
        id0: u64,
        name0: vector<u8>,
        owner0: address,
    }

    public fun new_registry(): Registry {
        Registry {
            next_id: 0,
            has0: false,
            id0: 0,
            name0: b"",
            owner0: @0x0
        }
    }

    /// Минтим ровно один NFT (#0) для демо
    public fun mint(r: &mut Registry, to: address, name: vector<u8>) {
        assert!(!r.has0, 1);
        let id = r.next_id;
        r.next_id = id + 1;

        r.id0 = id;
        r.name0 = name;
        r.owner0 = to;
        r.has0 = true;
    }

    public fun transfer(r: &mut Registry, id: u64, to: address) {
        assert!(r.has0, 2);
        assert!(r.id0 == id, 3);
        r.owner0 = to;
    }

    public fun get_owner(r: &Registry, id: u64): address {
        assert!(r.has0, 4);
        assert!(r.id0 == id, 5);
        r.owner0
    }

    // «Поглощаем» реестр, чтобы не было implicit drop
    fun destroy_registry(r: Registry) {
        let Registry {
            next_id: _,
            has0: _,
            id0: _,
            name0: _,
            owner0: _
        } = r;
    }

    /// DEMO: минт → трансфер → проверка владельца
    public entry fun entry_demo(_s: &signer) {
        let r = new_registry();
        mint(&mut r, @0x1, b"Demo NFT");
        transfer(&mut r, 0, @0x2);
        let owner = get_owner(&r, 0);
        assert!(owner == @0x2, 0);
        destroy_registry(r);
    }

// Для юнит-тестов: публичный «съедатель» реестра
    #[test_only]
    public fun destroy_for_test(r: Registry) {
        destroy_registry(r);
    }
   
// Публичная обёртка для юнит-тестов
    #[test_only]
    public fun destroy_registry_for_test(r: Registry) { destroy_registry(r); }
}
