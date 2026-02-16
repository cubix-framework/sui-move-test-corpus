module weather_oracle::weather_oracle;

public fun get_weather(clock: &sui::clock::Clock): std::string::String {
    let random  = clock.timestamp_ms() % 10;
    let weather = if (random < 3) {
        b"sunny".to_string()
    } else if (random < 6) {
        b"cloudy".to_string()
    } else if (random < 9) {
        b"rainy".to_string()
    } else {
        b"snowy".to_string()
    };
    weather
}

