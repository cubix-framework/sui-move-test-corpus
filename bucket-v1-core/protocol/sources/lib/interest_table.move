module bucket_protocol::interest {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::clock::{Self, Clock};

    use bucket_protocol::math::mul_factor_u256;
    use bucket_protocol::constants;
    
    friend bucket_protocol::buck;
    friend bucket_protocol::bucket;
    friend bucket_protocol::bottle;

    const EOverflow: u64 = 0;
    const ETimestamp: u64 = 1;

    struct InterestTable has store, key {
        id: UID,
        interest_rate: u256,
        active_interest_index: u256,
        last_active_index_update: u64,
        // gather interests, admin can withdraw interests afterwards
        interest_payable: u256,
    }

    struct BottleInterestIndex has store, key {
        id: UID,
        active_interest_index: u256,
    }

    public(friend) fun new_interest_table(clock: &Clock, ctx: &mut TxContext): InterestTable {
        InterestTable {
            id: object::new(ctx),
            interest_rate: 0,   // set interest rate per ms (4% per year, 4/31536000000 * 1e25 = 1268391679350583)
            active_interest_index: constants::interest_precision(),
            last_active_index_update: clock::timestamp_ms(clock),
            interest_payable: 0,
        }
    }

    public(friend) fun new_bottle_interest_index(active_interest_index: u256, ctx: &mut TxContext): BottleInterestIndex {
        BottleInterestIndex {
            id: object::new(ctx),
            active_interest_index: active_interest_index,
        }
    }

    public(friend) fun set_interest_rate(interest_table: &mut InterestTable, new_interest_rate: u256, bucket_active_buck_amount: u64, clock: &Clock) {
        if (new_interest_rate != interest_table.interest_rate) {
            accrue_active_interests(interest_table, bucket_active_buck_amount, clock);
            interest_table.last_active_index_update = clock::timestamp_ms(clock);
            interest_table.interest_rate = new_interest_rate;
        };
    }

    public(friend) fun collect_interests(table: &mut InterestTable): u64 {
        let interest_payable = table.interest_payable;
        table.interest_payable = 0;
        
        assert!(interest_payable <= (constants::max_u64() as u256), EOverflow);
        (interest_payable as u64)
    }

    // notice: must update bottle's debt (+interest) before calling this function
    public(friend) fun update_bottle_interest_index(
        bottle_interest_index: &mut BottleInterestIndex,
        current_interest_index: u256,
    ){
        if (bottle_interest_index.active_interest_index < current_interest_index) {
            bottle_interest_index.active_interest_index = current_interest_index;
        };
    }

    public(friend) fun accrue_active_interests(
        interest_table: &mut InterestTable, 
        bucket_buck_amount: u64, 
        clock: &Clock
    ): (u256, u256) {
        let (current_interest_index, interest_factor) = calculate_interest_index(interest_table, clock);
        let active_interest = 0;
        if (interest_factor > 0) {
            // total active debt * interest
            active_interest = 
                mul_factor_u256(
                    (bucket_buck_amount as u256),
                    interest_factor, 
                    constants::interest_precision()
                );
            interest_table.interest_payable = interest_table.interest_payable + active_interest;
            interest_table.active_interest_index = current_interest_index;
            interest_table.last_active_index_update = clock::timestamp_ms(clock);
        };

        (current_interest_index, active_interest)
    }

    public(friend) fun calculate_interest_index(interest_table: &InterestTable, clock: &Clock): (u256, u256) {
        let last_active_index_update_cache = interest_table.last_active_index_update;
        assert!(clock::timestamp_ms(clock) >= last_active_index_update_cache, ETimestamp);
        if (clock::timestamp_ms(clock) == last_active_index_update_cache) {
            return (interest_table.active_interest_index, 0)
        };
        let current_interest = interest_table.interest_rate;
        let current_interest_index = interest_table.active_interest_index;
        let interest_factor = 0;
        if (current_interest > 0) {
            let time_delta = clock::timestamp_ms(clock) - last_active_index_update_cache;
            interest_factor = (time_delta as u256) * current_interest;
            current_interest_index = 
                current_interest_index + 
                mul_factor_u256(current_interest_index, interest_factor, constants::interest_precision());
        };
        (current_interest_index, interest_factor)
    }

    public fun get_interest_table_info(interest_table: &InterestTable): (u256, u256, u64, u256) {
        (
            interest_table.interest_rate,
            interest_table.active_interest_index,
            interest_table.last_active_index_update,
            interest_table.interest_payable
        )
    }

    public fun get_bottle_interest_index(bottle_interest_index: &BottleInterestIndex): u256 {
        bottle_interest_index.active_interest_index
    }

    public fun get_interest_rate(interest_table: &InterestTable): u256 {
        interest_table.interest_rate
    }

    public fun get_active_interest_index(interest_table: &InterestTable): u256 {
        interest_table.active_interest_index
    }

    public fun get_last_active_index_update(interest_table: &InterestTable): u64 {
        interest_table.last_active_index_update
    }

    public fun get_interest_payable(interest_table: &InterestTable): u256 {
        interest_table.interest_payable
    }
}