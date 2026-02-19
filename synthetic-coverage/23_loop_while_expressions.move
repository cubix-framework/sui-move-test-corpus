// Synthetic test file for LoopExpression and WhileExpression node pairs
// Covers: LoopExpression/WhileExpression -> various child expression types

module synthetic::loop_while_expressions {

    // PAIR: LoopExpression -> HiddenExpressionAbortExpression
    fun loop_abort() {
        loop abort 1
    }

    // PAIR: LoopExpression -> HiddenExpressionAssignExpression
    fun loop_assign() {
        let x;
        loop x = 5
    }

    // PAIR: LoopExpression -> HiddenExpressionIdentifiedExpression
    fun loop_identified() {
        loop 'lbl: { break }
    }

    // PAIR: LoopExpression -> HiddenExpressionLambdaExpression
    fun loop_lambda() {
        loop |x| x
    }

    // PAIR: LoopExpression -> HiddenExpressionMatchExpression
    fun loop_match(x: u64) {
        loop match (x) { _ => break }
    }

    // PAIR: LoopExpression -> HiddenExpressionQuantifierExpression
    spec fun loop_quantifier() {
        loop forall x: u64: x > 0
    }

    // PAIR: LoopExpression -> HiddenExpressionReturnExpression
    fun loop_return() {
        loop return 5
    }

    // PAIR: LoopExpression -> HiddenExpressionVectorExpression
    fun loop_vector() {
        loop vector[1, 2]
    }

    // PAIR: LoopExpression -> HiddenExpressionWhileExpression
    fun loop_while() {
        loop while (true) { break }
    }

    // PAIR: WhileExpression -> HiddenExpressionAbortExpression
    fun while_abort() {
        while (true) abort 1
    }

    // PAIR: WhileExpression -> HiddenExpressionAssignExpression
    fun while_assign() {
        let x;
        while (true) x = 5
    }

    // PAIR: WhileExpression -> HiddenExpressionIdentifiedExpression
    fun while_identified() {
        while (true) 'lbl: { break }
    }

    // PAIR: WhileExpression -> HiddenExpressionLambdaExpression
    fun while_lambda() {
        while (true) |x| x
    }

    // PAIR: WhileExpression -> HiddenExpressionLoopExpression
    fun while_loop() {
        while (true) loop { break }
    }

    // PAIR: WhileExpression -> HiddenExpressionMatchExpression
    fun while_match(x: u64) {
        while (true) match (x) { _ => break }
    }

    // PAIR: WhileExpression -> HiddenExpressionQuantifierExpression
    spec fun while_quantifier() {
        while (true) forall x: u64: x > 0
    }

    // PAIR: WhileExpression -> HiddenExpressionReturnExpression
    fun while_return() {
        while (true) return 5
    }

    // PAIR: WhileExpression -> HiddenExpressionVectorExpression
    fun while_vector() {
        while (true) vector[1, 2]
    }

    // PAIR: WhileExpression -> HiddenExpressionWhileExpression
    fun while_while() {
        while (true) while (false) { break }
    }
}
