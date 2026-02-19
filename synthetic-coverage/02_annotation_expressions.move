// Synthetic test file for AnnotationExpression node pairs
// Covers: AnnotationExpression -> various HiddenExpression child types

module synthetic::annotation_expressions {

    // PAIR: AnnotationExpression -> HiddenExpressionAbortExpression
    fun annotation_with_abort(): u64 {
        (abort 5 : u64)
    }

    // PAIR: AnnotationExpression -> HiddenExpressionAssignExpression
    fun annotation_with_assign(): u64 {
        let x;
        (x = 5 : u64)
    }

    // PAIR: AnnotationExpression -> HiddenExpressionCastExpression
    fun annotation_with_cast(x: u8): u64 {
        (x as u64 : u64)
    }

    // PAIR: AnnotationExpression -> HiddenExpressionMatchExpression
    fun annotation_with_match(x: u64): u64 {
        (match (x) { _ => 0 } : u64)
    }

    // PAIR: AnnotationExpression -> HiddenExpressionQuantifierExpression
    spec fun annotation_with_quantifier(): bool {
        (forall x: u64: x > 0 : bool)
    }

    // PAIR: AnnotationExpression -> HiddenExpressionVectorExpression
    fun annotation_with_vector(): vector<u64> {
        (vector[1, 2] : vector<u64>)
    }

    // PAIR: AnnotationExpression -> HiddenExpressionWhileExpression
    fun annotation_with_while(): u64 {
        (while (true) { break } : u64)
    }
}
