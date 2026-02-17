#[allow(unused)]
module typus_framework::vault {
    use std::string::String;

    public struct TypusBidReceipt has key, store {
        id: UID,
        vid: ID,
        index: u64,
        metadata: String,
        u64_padding: vector<u64>,
    }

    public struct TypusDepositReceipt has key, store {
        id: UID,
        vid: ID,
        index: u64,
        metadata: String,
        u64_padding: vector<u64>,
    }
}