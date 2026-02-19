// Synthetic test file for ArgList node pairs
// Covers: ArgList -> various HiddenExpression types

module synthetic::function_arguments {

    fun dummy(_x: u64) {}

    // PAIR: ArgList -> HiddenExpressionAssignExpression
    fun arg_with_assign() {
        let x;
        dummy(x = 5)
    }

    // PAIR: ArgList -> HiddenExpressionMatchExpression
    fun arg_with_match(x: u64) {
        dummy(match (x) { _ => 0 })
    }

    // PAIR: ArgList -> HiddenExpressionQuantifierExpression
    spec fun arg_with_quantifier() {
        dummy(forall x: u64: x > 0)
    }

    // PAIR: ArgList -> HiddenExpressionVectorExpression
    fun arg_with_vector() {
        dummy(vector[1, 2])
    }

    // PAIR: ArgList -> HiddenExpressionWhileExpression
    fun arg_with_while() {
        dummy(while (true) { break })
    }
}
