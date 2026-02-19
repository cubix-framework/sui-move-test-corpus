// Synthetic test file for LetStatement node pairs
// Covers: LetStatement -> various HiddenExpression and binding types

module synthetic::let_statements {

    // PAIR: LetStatement -> BindListOrBindList
    fun let_or_bind() {
        let x | y = 5;
    }

    // PAIR: LetStatement -> HiddenExpressionMatchExpression
    fun let_match(y: u64) {
        let x = match (y) { _ => 1 };
    }

    // PAIR: LetStatement -> HiddenExpressionQuantifierExpression
    spec fun let_quantifier() {
        let b = forall x: u64: x > 0;
    }

    // PAIR: LetStatement -> HiddenExpressionReturnExpression
    fun let_return() {
        let x = return 5;
    }

    // PAIR: LetStatement -> HiddenExpressionVectorExpression
    fun let_vector() {
        let v = vector[1, 2, 3];
    }
}
