// Synthetic test file for VectorExpression node pairs
// Covers: VectorExpression, VectorExpressionInternal02 -> various child types

module synthetic::vector_expressions {

    // PAIR: VectorExpression -> HiddenExpressionAbortExpression
    fun vector_abort() {
        vector[abort 1]
    }

    // PAIR: VectorExpression -> HiddenExpressionAssignExpression
    fun vector_assign() {
        let x;
        vector[x = 5]
    }

    // PAIR: VectorExpression -> HiddenExpressionLambdaExpression
    fun vector_lambda() {
        vector[|x| x]
    }

    // PAIR: VectorExpression -> HiddenExpressionLoopExpression
    fun vector_loop() {
        vector[loop { break 1 }]
    }

    // PAIR: VectorExpression -> HiddenExpressionMatchExpression
    fun vector_match(x: u64) {
        vector[match (x) { _ => 1 }]
    }

    // PAIR: VectorExpression -> HiddenExpressionQuantifierExpression
    spec fun vector_quantifier() {
        vector[forall x: u64: x > 0]
    }

    // PAIR: VectorExpression -> HiddenExpressionReturnExpression
    fun vector_return() {
        vector[return 5]
    }

    // PAIR: VectorExpression -> HiddenExpressionVectorExpression
    fun vector_vector() {
        vector[vector[1, 2]]
    }

    // PAIR: VectorExpression -> HiddenExpressionWhileExpression
    fun vector_while() {
        vector[while (true) { break 1 }]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionAbortExpression
    fun vector_internal_abort() {
        vector<u64>[abort 1]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionAssignExpression
    fun vector_internal_assign() {
        let x;
        vector<u64>[x = 5]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionLambdaExpression
    fun vector_internal_lambda() {
        vector<|u64| -> u64>[|x| x]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionLoopExpression
    fun vector_internal_loop() {
        vector<u64>[loop { break 1 }]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionMatchExpression
    fun vector_internal_match(x: u64) {
        vector<u64>[match (x) { _ => 1 }]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionQuantifierExpression
    spec fun vector_internal_quantifier() {
        vector<bool>[forall x: u64: x > 0]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionReturnExpression
    fun vector_internal_return() {
        vector<u64>[return 5]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionVectorExpression
    fun vector_internal_vector() {
        vector<vector<u64>>[vector[1, 2]]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenExpressionWhileExpression
    fun vector_internal_while() {
        vector<u64>[while (true) { break 1 }]
    }
}
