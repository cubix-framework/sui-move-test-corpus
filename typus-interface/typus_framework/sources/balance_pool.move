#[allow(unused)]
module typus_framework::balance_pool {
    use std::type_name::TypeName;

    use typus_framework::authority::Authority;

    public struct BalancePool has key, store {
        id: UID,
        balance_infos: vector<BalanceInfo>,
        authority: Authority,
    }

    public struct BalanceInfo has copy, drop, store {
        token: TypeName,
        value: u64,
    }
}