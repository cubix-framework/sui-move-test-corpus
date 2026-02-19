// Synthetic test file for AbortExpression node pairs
// Covers: AbortExpression -> various HiddenExpression child types

module synthetic::abort_constructs {

    // PAIR: AbortExpression -> HiddenExpressionAssignExpression
    fun abort_with_assign() {
        let x;
        abort x = 5
    }

    // PAIR: AbortExpression -> HiddenExpressionLambdaExpression
    fun abort_with_lambda() {
        abort |x, y| x
    }

    // PAIR: AbortExpression -> HiddenExpressionLoopExpression
    fun abort_with_loop() {
        abort loop { break }
    }

    // PAIR: AbortExpression -> HiddenExpressionMatchExpression
    fun abort_with_match(x: u64) {
        abort match (x) { _ => 0 }
    }

    // PAIR: AbortExpression -> HiddenExpressionQuantifierExpression
    spec fun abort_with_quantifier(): bool {
        abort forall x: u64: x > 0
    }

    // PAIR: AbortExpression -> HiddenExpressionReturnExpression
    fun abort_with_return() {
        abort return 5
    }

    // PAIR: AbortExpression -> HiddenExpressionVectorExpression
    fun abort_with_vector() {
        abort vector[1, 2]
    }

    // PAIR: AbortExpression -> HiddenExpressionWhileExpression
    fun abort_with_while() {
        abort while (true) { break }
    }
}
