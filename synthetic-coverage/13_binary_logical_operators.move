// Synthetic test file for BinaryExpression2/3 (|| and && operators) node pairs
// Covers: BinaryExpression2/3 -> various HiddenExpression RHS types

module synthetic::binary_logical_operators {

    // PAIR: BinaryExpression2 -> HiddenExpressionAbortExpression
    fun or_abort(a: bool) {
        a || abort 1
    }

    // PAIR: BinaryExpression2 -> HiddenExpressionIdentifiedExpression
    fun or_identified(a: bool, b: bool) {
        a || 'lbl: b
    }

    // PAIR: BinaryExpression2 -> HiddenExpressionLambdaExpression
    fun or_lambda(a: bool) {
        a || |x| x
    }

    // PAIR: BinaryExpression2 -> HiddenExpressionLoopExpression
    fun or_loop(a: bool) {
        a || loop { break 1 }
    }

    // PAIR: BinaryExpression2 -> HiddenExpressionMatchExpression
    fun or_match(a: bool, x: u64) {
        a || match (x) { y => true }
    }

    // PAIR: BinaryExpression2 -> HiddenExpressionQuantifierExpression
    spec fun or_quantifier(a: bool) {
        ensures a || forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression2 -> HiddenExpressionVectorExpression
    fun or_vector(a: bool) {
        a || vector[1, 2]
    }

    // PAIR: BinaryExpression2 -> HiddenExpressionWhileExpression
    fun or_while(a: bool) {
        a || while (true) { break }
    }

    // PAIR: BinaryExpression3 -> HiddenExpressionIdentifiedExpression
    spec fun and_identified(a: bool, b: bool) {
        ensures a && 'label: b;
    }

    // PAIR: BinaryExpression3 -> HiddenExpressionLambdaExpression
    fun and_lambda(a: bool) {
        a && |x| x
    }

    // PAIR: BinaryExpression3 -> HiddenExpressionLoopExpression
    fun and_loop(a: bool) {
        a && loop { break true }
    }

    // PAIR: BinaryExpression3 -> HiddenExpressionMatchExpression
    fun and_match(a: bool, x: u64) {
        a && match (x) { y => true }
    }

    // PAIR: BinaryExpression3 -> HiddenExpressionQuantifierExpression
    spec fun and_quantifier(a: bool) {
        ensures a && forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression3 -> HiddenExpressionVectorExpression
    fun and_vector(a: bool) {
        a && vector[1, 2]
    }

    // PAIR: BinaryExpression3 -> HiddenExpressionWhileExpression
    fun and_while(a: bool) {
        a && while (true) { break }
    }
}
