// Synthetic test file for BorrowExpression and DereferenceExpression node pairs
// Covers: BorrowExpression/DereferenceExpression -> various HiddenExpression child types

module synthetic::borrow_dereference {

    // PAIR: BorrowExpression -> HiddenExpressionLambdaExpression
    fun borrow_lambda() {
        & |x: u64| x
    }

    // PAIR: BorrowExpression -> HiddenExpressionMatchExpression
    fun borrow_match(x: u64) {
        & match (x) { _ => 1 }
    }

    // PAIR: BorrowExpression -> HiddenExpressionVectorExpression
    fun borrow_vector() {
        & vector[1, 2]
    }

    // PAIR: BorrowExpression -> HiddenExpressionWhileExpression
    fun borrow_while() {
        & while (true) { break }
    }

    // PAIR: DereferenceExpression -> HiddenExpressionAbortExpression
    fun deref_abort() {
        *abort 0
    }

    // PAIR: DereferenceExpression -> HiddenExpressionIdentifiedExpression
    fun deref_identified(x: u64) {
        *'lab: x
    }

    // PAIR: DereferenceExpression -> HiddenExpressionLambdaExpression
    fun deref_lambda() {
        *|x: u64| x + 1
    }

    // PAIR: DereferenceExpression -> HiddenExpressionLoopExpression
    fun deref_loop() {
        *loop { break 5 }
    }

    // PAIR: DereferenceExpression -> HiddenExpressionMacroCallExpression
    fun deref_macro() {
        *assert!(true, 0)
    }

    // PAIR: DereferenceExpression -> HiddenExpressionMatchExpression
    fun deref_match(x: u64) {
        *match (x) { _ => 0 }
    }

    // PAIR: DereferenceExpression -> HiddenExpressionReturnExpression
    fun deref_return() {
        *return 5
    }

    // PAIR: DereferenceExpression -> HiddenExpressionVectorExpression
    fun deref_vector() {
        *vector[1, 2]
    }

    // PAIR: DereferenceExpression -> HiddenExpressionWhileExpression
    fun deref_while() {
        *while (true) { break 0 }
    }

    // NOTE: DereferenceExpression -> HiddenExpressionQuantifierExpression is IMPOSSIBLE
    // *forall x: u64: x > 0 breaks the parser and eats sentinel functions
    // NOTE: BorrowExpression -> HiddenExpressionQuantifierExpression is IMPOSSIBLE
    // & forall x: u64: x > 0 breaks the parser and eats sentinel functions
}
