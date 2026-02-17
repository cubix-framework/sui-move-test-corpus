module bucket_protocol::reservoir_events {

    use sui::event;

    friend bucket_protocol::reservoir;

    struct ChargeReservior<phantom T> has copy, drop {
        inflow_amount: u64,
        buck_amount: u64,
    }

    public(friend) fun emit_charge_reservoir<T>(
        inflow_amount: u64,
        buck_amount: u64,
    ) {
        event::emit(ChargeReservior<T> { 
            inflow_amount,
            buck_amount,
        });
    }

    struct DischargeReservior<phantom T> has copy, drop {
        outflow_amount: u64,
        buck_amount: u64,
    }

    public(friend) fun emit_discharge_reservoir<T>(
        outflow_amount: u64,
        buck_amount: u64,
    ) {
        event::emit(DischargeReservior<T> {
            outflow_amount,
            buck_amount,
        });
    }
}