// Synthetic test file for CastExpression node pairs
// Covers: CastExpression -> various types and LHS expressions

module synthetic::cast_expressions {

    // PAIR: CastExpression -> HiddenExpressionMatchExpression
    fun cast_match(x: u64): u64 {
        match (x) { _ => 1 } as u64
    }

    // PAIR: CastExpression -> HiddenExpressionVectorExpression
    fun cast_vector(): vector<u64> {
        vector[1, 2] as vector<u64>
    }

    // PAIR: CastExpression -> HiddenTypeFunctionType
    fun cast_function_type(x: u64) {
        x as |u64| -> bool
    }
}
