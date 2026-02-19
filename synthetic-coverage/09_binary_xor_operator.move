// Synthetic test file for BinaryExpression12 (^ xor operator) node pairs
// Covers: BinaryExpression12 -> various HiddenExpression RHS types

module synthetic::binary_xor_operator {

    // PAIR: BinaryExpression12 -> HiddenExpressionAbortExpression
    fun xor_abort(a: u64) {
        a ^ abort 1
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionIdentifiedExpression
    fun xor_identified(a: u64, x: u64) {
        a ^ 'label: x
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionIfExpression
    fun xor_if(x: u64, y: u64) {
        if (true) x ^ y
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionLambdaExpression
    fun xor_lambda(a: u64) {
        a ^ |x| x
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionLoopExpression
    fun xor_loop(a: u64) {
        a ^ loop { break 1 }
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionMatchExpression
    fun xor_match(a: u64, x: u64) {
        a ^ match (x) { p => 1 }
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionQuantifierExpression
    spec fun xor_quantifier(a: u64) {
        ensures a ^ forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionVectorExpression
    fun xor_vector(a: u64) {
        a ^ vector[1, 2]
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionWhileExpression
    fun xor_while(a: u64) {
        a ^ while (true) { break 1 }
    }
}
