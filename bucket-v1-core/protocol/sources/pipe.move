module bucket_protocol::pipe {

    // Dependecies

    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::TxContext;
    use bucket_protocol::pipe_events;

    friend bucket_protocol::buck;

    // Errors

    const EInputTooMuch: u64 = 0;
    fun err_input_too_much() { abort EInputTooMuch }

    const EDestroyNonEmptyPipe: u64 = 1;
    fun err_destroy_non_empty_pipe() { abort EDestroyNonEmptyPipe }

    // Objects

    struct PipeType<phantom T, phantom R: drop> has copy, drop, store {}

    struct Pipe<phantom T, phantom R: drop> has key, store {
        id: UID,
        output_volume: u64,
    }

    struct OutputCarrier<phantom T, phantom R: drop> {
        content: Balance<T>,
    }

    struct InputCarrier<phantom T, phantom R: drop> {
        content: Balance<T>,
    }

    // Friend Functions

    public(friend) fun new_type<T, R: drop>(): PipeType<T, R> {
        PipeType<T, R> {}
    }

    public(friend) fun new_pipe<T, R: drop>(ctx: &mut TxContext): Pipe<T, R> {
        Pipe<T, R> {
            id: object::new(ctx),
            output_volume: 0,
        }
    }

    public(friend) fun destroy_pipe<T, R: drop>(
        pipe: Pipe<T, R>,
    ) {
        let Pipe { id, output_volume } = pipe;
        if (output_volume > 0) err_destroy_non_empty_pipe();
        object::delete(id);
    }

    public(friend) fun destroy_buck_pipe<T, R: drop>(
        pipe: Pipe<T, R>,
    ) {
        let Pipe { id, output_volume: _ } = pipe;
        object::delete(id);
    }

    // Output Functions

    public(friend) fun output<T, R: drop>(
        pipe: &mut Pipe<T, R>,
        content: Balance<T>,
    ): OutputCarrier<T, R> {
        let volume = balance::value(&content);
        pipe_events::emit_output<T, R>(volume);
        pipe.output_volume = output_volume(pipe) + volume;
        OutputCarrier<T, R> { content }
    }

    public fun destroy_output_carrier<T, R: drop>(
        _: R,
        carrier: OutputCarrier<T, R>,
    ): Balance<T> {
        let OutputCarrier { content } = carrier;
        content
    }

    // Input Functions

    public fun input<T, R: drop>(
        _: R,
        content: Balance<T>,
    ): InputCarrier<T, R> {
        pipe_events::emit_input<T, R>(&content);
        InputCarrier<T, R> { content }
    }

    public(friend) fun destroy_input_carrier<T, R: drop>(
        pipe: &mut Pipe<T, R>,
        carrier: InputCarrier<T, R>,
    ): Balance<T> {
        let input_volume = input_carrier_volume(&carrier);
        let output_volume = output_volume(pipe);
        if (output_volume < input_volume)
            err_input_too_much();
        pipe.output_volume = output_volume - input_volume;
        let InputCarrier { content } = carrier;
        content
    }

    // Getter Functions

    public fun output_volume<T, R: drop>(pipe: &Pipe<T, R>): u64 {
        pipe.output_volume
    }

    public fun output_carrier_volume<T, R: drop>(carrier: &OutputCarrier<T, R>): u64 {
        balance::value(&carrier.content)
    }

    public fun input_carrier_volume<T, R: drop>(carrier: &InputCarrier<T, R>): u64 {
        balance::value(&carrier.content)
    }
}