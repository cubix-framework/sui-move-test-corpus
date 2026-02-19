// Synthetic test file for MoveOrCopyExpression and UnaryExpression node pairs
// Covers: MoveOrCopyExpression, UnaryExpression -> various child types

module synthetic::move_copy_unary {

    // PAIR: MoveOrCopyExpression -> HiddenExpressionAbortExpression
    fun move_abort() {
        move abort 1
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionLambdaExpression
    fun move_lambda() {
        move |x| x
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionLoopExpression
    fun move_loop() {
        move loop { break 1 }
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionMatchExpression
    fun move_match(x: u64) {
        move match (x) { _ => 1 }
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionQuantifierExpression
    spec fun move_quantifier() {
        move forall x: u64: x > 0
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionReturnExpression
    fun move_return() {
        move return 5
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionVectorExpression
    fun move_vector() {
        move vector[1, 2]
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionWhileExpression
    fun move_while() {
        move while (true) { break 1 }
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionAbortExpression (copy variant)
    fun copy_abort() {
        copy abort 1
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionLambdaExpression (copy variant)
    fun copy_lambda() {
        copy |x| x
    }

    // PAIR: UnaryExpression -> HiddenExpressionAbortExpression
    fun unary_abort() {
        !abort true
    }

    // PAIR: UnaryExpression -> HiddenExpressionLambdaExpression
    fun unary_lambda() {
        !|x| x
    }

    // PAIR: UnaryExpression -> HiddenExpressionLoopExpression
    fun unary_loop() {
        !loop { break true }
    }

    // PAIR: UnaryExpression -> HiddenExpressionMatchExpression
    fun unary_match(x: u64) {
        !match (x) { _ => true }
    }

    // PAIR: UnaryExpression -> HiddenExpressionQuantifierExpression
    spec fun unary_quantifier() {
        !forall x: u64: x > 0
    }

    // PAIR: UnaryExpression -> HiddenExpressionReturnExpression
    fun unary_return() {
        !return true
    }

    // PAIR: UnaryExpression -> HiddenExpressionVectorExpression
    fun unary_vector() {
        !vector[true]
    }

    // PAIR: UnaryExpression -> HiddenExpressionWhileExpression
    fun unary_while() {
        !while (true) { break true }
    }
}
