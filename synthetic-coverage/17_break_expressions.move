// Synthetic test file for BreakExpression node pairs
// Covers: BreakExpression -> various HiddenExpression child types

module synthetic::break_expressions {

    // PAIR: BreakExpression -> HiddenExpressionAbortExpression
    fun break_with_abort() {
        loop { break abort 1 }
    }

    // PAIR: BreakExpression -> HiddenExpressionBinaryExpression
    fun break_with_binary() {
        let x = 1;
        loop { break x + 1 }
    }

    // PAIR: BreakExpression -> HiddenExpressionCallExpression
    fun break_with_call() {
        loop { break f() }
    }

    fun f(): u64 { 0 }

    // PAIR: BreakExpression -> HiddenExpressionCastExpression
    fun break_with_cast(x: u8) {
        loop { break x as u64 }
    }

    // PAIR: BreakExpression -> HiddenExpressionLambdaExpression
    fun break_with_lambda() {
        loop { break |x| x }
    }

    // PAIR: BreakExpression -> HiddenExpressionMacroCallExpression
    fun break_with_macro() {
        loop { break f!() }
    }

    // PAIR: BreakExpression -> HiddenExpressionMatchExpression
    fun break_with_match(x: u64) {
        loop { break match (x) { _ => 1 } }
    }

    // PAIR: BreakExpression -> HiddenExpressionQuantifierExpression
    spec fun break_with_quantifier() {
        loop { break forall x: u64: x > 0 }
    }

    // PAIR: BreakExpression -> HiddenExpressionReturnExpression
    fun break_with_return() {
        loop { break return 5 }
    }

    // PAIR: BreakExpression -> HiddenExpressionVectorExpression
    fun break_with_vector() {
        loop { break vector[1, 2] }
    }

    // PAIR: BreakExpression -> HiddenExpressionWhileExpression
    fun break_with_while() {
        loop { break while (true) { break 1 } }
    }
}
