// Synthetic test file for BinaryExpression11 (| bitor operator) node pairs
// Covers: BinaryExpression11 -> various HiddenExpression RHS types

module synthetic::binary_bitor_operator {

    // PAIR: BinaryExpression11 -> HiddenExpressionAbortExpression
    fun bitor_abort(a: u64) {
        a | abort 1
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionCallExpression
    fun bitor_call() {
        f() | g()
    }

    fun f(): u64 { 0 }
    fun g(): u64 { 0 }

    // PAIR: BinaryExpression11 -> HiddenExpressionIdentifiedExpression
    fun bitor_identified(a: u64, x: u64) {
        a | 'label: x
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionIfExpression
    fun bitor_if(x: u64, y: u64) {
        if (true) x | y
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionLambdaExpression
    fun bitor_lambda(a: u64) {
        a | |x| x
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionLoopExpression
    fun bitor_loop(a: u64) {
        a | loop { break 1 }
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionMatchExpression
    fun bitor_match(x: u64, a: u64) {
        match (x) { p => 1 } | a
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionQuantifierExpression
    spec fun bitor_quantifier(a: u64) {
        ensures a | forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionReturnExpression
    fun bitor_return(a: u64, b: u64) {
        a | return b
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionVectorExpression
    fun bitor_vector(a: u64) {
        vector[1, 2] | a
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionWhileExpression
    fun bitor_while(a: u64) {
        a | while (true) { break 1 }
    }
}
