// Synthetic test file for ReturnExpression node pairs
// Covers: ReturnExpression1 -> various HiddenExpression child types

module synthetic::return_expressions {

    // PAIR: ReturnExpression1 -> HiddenExpressionAbortExpression
    fun return_abort() {
        return abort 1
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionAssignExpression
    fun return_assign() {
        let x;
        return x = 5
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionCastExpression
    fun return_cast(x: u8): u64 {
        return x as u64
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionIdentifiedExpression
    fun return_identified(x: u64): u64 {
        return 'lbl: x
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionIfExpression
    fun return_if(c: bool): u64 {
        return if (c) 1 else 2
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionLambdaExpression
    fun return_lambda() {
        return |x| x
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionLoopExpression
    fun return_loop(): u64 {
        return loop { break 1 }
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionMacroCallExpression
    fun return_macro(): u64 {
        return foo!()
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionMatchExpression
    fun return_match(x: u64): u64 {
        return match (x) { _ => 1 }
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionQuantifierExpression
    spec fun return_quantifier(): bool {
        return forall x: u64: x > 0
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionReturnExpression
    fun return_return(): u64 {
        return return 5
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionVectorExpression
    fun return_vector(): vector<u64> {
        return vector[1, 2]
    }

    // PAIR: ReturnExpression1 -> HiddenExpressionWhileExpression
    fun return_while(): u64 {
        return while (true) { break 1 }
    }
}
