module age_calculator::age_calculator;

public fun calculate_age(clock: &sui::clock::Clock, birth_date: u64): u64 {
    let current_time = clock.timestamp_ms();
    let age_ms = current_time - birth_date;
    age_ms / 1000 / 60 / 60 / 24 / 365
}
