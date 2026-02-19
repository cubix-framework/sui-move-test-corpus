// Synthetic test file for BinaryExpression14/15 (<< and >> shift operators) node pairs
// Covers: BinaryExpression14/15 -> various HiddenExpression RHS types

module synthetic::binary_shift_operators {

    // PAIR: BinaryExpression14 -> HiddenExpressionAbortExpression
    fun shl_abort(a: u64, b: u64) {
        a << abort b
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionIdentifiedExpression
    fun shl_identified(a: u64, b: u8) {
        a << 'lab: b
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionIfExpression
    fun shl_if(a: u64, c: bool, b: u8, d: u8) {
        a << if (c) { b } else { d }
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionLambdaExpression
    fun shl_lambda(a: u64) {
        a << |x| x
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionLoopExpression
    fun shl_loop(a: u64) {
        a << loop { break 1 }
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionMatchExpression
    fun shl_match(a: u64, x: u64) {
        a << match (x) { p => 1 }
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionQuantifierExpression
    spec fun shl_quantifier(a: u64) {
        ensures a << forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionVectorExpression
    fun shl_vector(a: u64) {
        a << vector[1, 2]
    }

    // PAIR: BinaryExpression14 -> HiddenExpressionWhileExpression
    fun shl_while(a: u64) {
        a << while (true) { break 1 }
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionAbortExpression
    fun shr_abort(a: u64) {
        a >> abort 1
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionIdentifiedExpression
    fun shr_identified(a: u64, x: u8) {
        a >> 'lbl: x
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionIfExpression
    fun shr_if(a: u64) {
        a >> if (true) 1 else 2
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionLambdaExpression
    fun shr_lambda(a: u64) {
        a >> |x| x
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionLoopExpression
    fun shr_loop(a: u64) {
        a >> loop { break 1 }
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionMacroCallExpression
    fun shr_macro(a: u64, x: u8) {
        a >> foo!(x)
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionMatchExpression
    fun shr_match(a: u64, x: u64) {
        a >> match (x) { _ => 1 }
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionQuantifierExpression
    spec fun shr_quantifier(a: u64) {
        ensures a >> forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionVectorExpression
    fun shr_vector(a: u64) {
        a >> vector[1, 2]
    }

    // PAIR: BinaryExpression15 -> HiddenExpressionWhileExpression
    fun shr_while(a: u64) {
        a >> while (true) { break 1 }
    }
}
