module my_event_emitter_ptb::my_event_emitter_ptb;

use std::string::String;
use sui::event;

public struct GreetingEvent has copy, drop {
    greeting: String,
}

public fun emit_greeting_event(greeting: String) {
    let event = GreetingEvent { greeting };
    event::emit(event);
}
