#[allow(unused)]
module typus_framework::authority {
    use sui::linked_table::LinkedTable;

    public struct Authority has store {
        whitelist: LinkedTable<address, bool>,
    }
}