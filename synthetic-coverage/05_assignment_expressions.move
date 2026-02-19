// Synthetic test file for AssignExpression node pairs
// Covers: AssignExpression -> various HiddenExpression RHS types

module synthetic::assignment_expressions {

    // PAIR: AssignExpression -> HiddenExpressionLoopExpression
    fun assign_with_loop() {
        let x;
        x = loop { break 1 }
    }

    // PAIR: AssignExpression -> HiddenExpressionMatchExpression
    fun assign_with_match(y: u64) {
        let x;
        x = match (y) { z => 1 }
    }

    // PAIR: AssignExpression -> HiddenExpressionQuantifierExpression
    spec fun assign_with_quantifier() {
        let x;
        x = forall n: u64: n > 0
    }

    // PAIR: AssignExpression -> HiddenExpressionReturnExpression
    fun assign_with_return() {
        let x;
        x = return 5
    }

    // PAIR: AssignExpression -> HiddenExpressionVectorExpression
    fun assign_with_vector() {
        let x;
        x = vector[1, 2, 3]
    }

    // PAIR: AssignExpression -> HiddenExpressionWhileExpression
    fun assign_with_while() {
        let x;
        x = while (true) { break }
    }
}
