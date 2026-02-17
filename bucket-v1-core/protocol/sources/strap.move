module bucket_protocol::strap {

    use std::option::{Self, Option};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::package;

    struct STRAP has drop {}

    struct BottleStrap<phantom T> has key, store {
        id: UID,
        fee_rate: Option<u64>,
    }

    fun init(otw: STRAP, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx);
    }

    public fun new<T>(ctx: &mut TxContext): BottleStrap<T> {
        BottleStrap {
            id: object::new(ctx),
            fee_rate: option::none(),
        }
    }

    public fun fee_rate<T>(strap: &BottleStrap<T>): Option<u64> {
        strap.fee_rate
    }

    public fun get_address<T>(strap: &BottleStrap<T>): address {
        object::id_to_address(object::borrow_id(strap))
    }

    friend bucket_protocol::bucket;
    public(friend) fun destroy<T>(strap: BottleStrap<T>) {
        let BottleStrap {
            id,
            fee_rate: _,
        } = strap;
        object::delete(id);
    }

    friend bucket_protocol::buck;
    public(friend) fun new_with_fee_rate<T>(
        fee_rate: u64,
        ctx: &mut TxContext,
    ): BottleStrap<T> {
        BottleStrap {
            id: object::new(ctx),
            fee_rate: option::some(fee_rate),
        }
    }
}