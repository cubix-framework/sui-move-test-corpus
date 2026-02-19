// Synthetic test file for BinaryExpression10 (.. range operator) node pairs
// Covers: BinaryExpression10 -> various HiddenExpression RHS types

module synthetic::binary_range_operator {

    // PAIR: BinaryExpression10 -> HiddenExpressionAbortExpression
    fun range_abort(a: u64) {
        a .. abort 1
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionCastExpression
    fun range_cast(a: u64, b: u8) {
        a .. b as u64
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionIdentifiedExpression
    fun range_identified(a: u64, b: u64) {
        a .. 'lbl: b
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionIfExpression
    fun range_if(a: u64) {
        a .. if (true) 1 else 2
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionLambdaExpression
    fun range_lambda(a: u64) {
        a .. |x| x
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionLoopExpression
    fun range_loop(a: u64) {
        a .. loop { break 1 }
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionMacroCallExpression
    fun range_macro(a: u64) {
        a .. foo!()
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionMatchExpression
    fun range_match(a: u64, x: u64) {
        a .. match (x) { p => 1 }
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionQuantifierExpression
    spec fun range_quantifier(a: u64) {
        ensures a .. forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionReturnExpression
    fun range_return(a: u64, b: u64) {
        a .. return b
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionVectorExpression
    fun range_vector(a: u64) {
        a .. vector[1, 2]
    }

    // PAIR: BinaryExpression10 -> HiddenExpressionWhileExpression
    fun range_while(a: u64) {
        a .. while (true) { break 1 }
    }
}
