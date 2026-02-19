// Synthetic test file for IdentifiedExpression node pairs
// Covers: IdentifiedExpression -> various HiddenExpression child types

module synthetic::identified_expressions {

    // PAIR: IdentifiedExpression -> HiddenExpressionAbortExpression
    fun identified_abort() {
        'label: abort 1
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionAssignExpression
    fun identified_assign() {
        let x;
        'label: x = 5
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionLambdaExpression
    fun identified_lambda() {
        'label: |x| x
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionLoopExpression
    fun identified_loop() {
        'label: loop { break 'label 1 }
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionMatchExpression
    fun identified_match(x: u64) {
        'label: match (x) { _ => 1 }
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionQuantifierExpression
    spec fun identified_quantifier() {
        'label: forall x: u64: x > 0
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionReturnExpression
    fun identified_return() {
        'label: return 5
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionVectorExpression
    fun identified_vector() {
        'label: vector[1, 2]
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionWhileExpression
    fun identified_while() {
        'label: while (true) { break 'label }
    }
}
