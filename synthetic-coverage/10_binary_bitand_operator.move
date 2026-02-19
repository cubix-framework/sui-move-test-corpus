// Synthetic test file for BinaryExpression13 (& bitand operator) node pairs
// Covers: BinaryExpression13 -> various HiddenExpression RHS types

module synthetic::binary_bitand_operator {

    // PAIR: BinaryExpression13 -> HiddenExpressionAbortExpression
    fun bitand_abort(a: u64, b: u64) {
        a & abort b
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionIdentifiedExpression
    fun bitand_identified(a: u64, b: u64) {
        a & 'lab: b
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionIfExpression
    fun bitand_if(a: u64, c: bool, b: u64, d: u64) {
        a & if (c) { b } else { d }
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionLambdaExpression
    fun bitand_lambda(a: u64) {
        a & |x| x
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionLoopExpression
    fun bitand_loop(a: u64) {
        a & loop { break 1 }
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionMatchExpression
    fun bitand_match(a: u64, x: u64) {
        a & match (x) { p => 1 }
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionQuantifierExpression
    spec fun bitand_quantifier(a: u64) {
        ensures a & forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionReturnExpression
    fun bitand_return(a: u64, b: u64) {
        a & return b
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionVectorExpression
    fun bitand_vector(a: u64) {
        a & vector[1, 2]
    }

    // PAIR: BinaryExpression13 -> HiddenExpressionWhileExpression
    fun bitand_while(a: u64) {
        a & while (true) { break 1 }
    }
}
