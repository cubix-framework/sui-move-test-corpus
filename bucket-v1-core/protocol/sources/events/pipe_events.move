module bucket_protocol::pipe_events {

    use sui::event;
    use sui::balance::{Self, Balance};

    friend bucket_protocol::pipe;

    struct Output<phantom T, phantom R: drop> has copy, drop {
        volume: u64,
    }

    public(friend) fun emit_output<T, R: drop>(
        volume: u64,
    ) {
        event::emit(Output<T, R> { volume });
    }

    struct Input<phantom T, phantom R: drop> has copy, drop {
        volume: u64,
    }

    public(friend) fun emit_input<T, R: drop>(
        content: &Balance<T>,
    ) {
        let volume = balance::value(content);
        event::emit(Input<T, R> { volume });
    }
}