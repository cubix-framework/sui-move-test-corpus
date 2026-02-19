// Synthetic test file for Block node pairs
// Covers: Block -> various HiddenExpression final expression types

module synthetic::block_expressions {

    // PAIR: Block -> HiddenExpressionLambdaExpression
    fun block_with_lambda(): u64 {
        { |x| x + 1 }
    }

    // PAIR: Block -> HiddenExpressionMatchExpression
    fun block_with_match(x: u64): u64 {
        { match (x) { _ => 1 } }
    }

    // PAIR: Block -> HiddenExpressionQuantifierExpression
    spec fun block_with_quantifier(): bool {
        { forall x: u64: x > 0 }
    }

    // PAIR: Block -> HiddenExpressionVectorExpression
    fun block_with_vector(): vector<u64> {
        { vector[1, 2, 3] }
    }

    // PAIR: BlockItemInternal0Expression -> HiddenExpressionMatchExpression
    fun block_item_match(x: u64) {
        { match (x) { _ => 1 }; }
    }

    // PAIR: BlockItemInternal0Expression -> HiddenExpressionQuantifierExpression
    spec fun block_item_quantifier() {
        { forall x: u64: x > 0; }
    }

    // PAIR: BlockItemInternal0Expression -> HiddenExpressionVectorExpression
    fun block_item_vector() {
        { vector[1, 2]; }
    }
}
