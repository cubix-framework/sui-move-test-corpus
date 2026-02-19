// Synthetic test file for IfExpression node pairs
// Covers: IfExpression -> various HiddenExpression child types

module synthetic::if_expressions {

    // PAIR: IfExpression -> HiddenExpressionAbortExpression (condition)
    fun if_condition_abort() {
        if (abort true) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionAssignExpression (condition)
    fun if_condition_assign() {
        let x;
        if (x = true) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionLambdaExpression (condition)
    fun if_condition_lambda() {
        if (|x| x) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionLoopExpression (condition)
    fun if_condition_loop() {
        if (loop { break true }) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionMatchExpression (condition)
    fun if_condition_match(x: u64) {
        if (match (x) { _ => true }) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionQuantifierExpression (condition)
    spec fun if_condition_quantifier() {
        if (forall x: u64: x > 0) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionReturnExpression (condition)
    fun if_condition_return() {
        if (return true) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionVectorExpression (condition)
    fun if_condition_vector() {
        if (vector[true]) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionWhileExpression (condition)
    fun if_condition_while() {
        if (while (true) { break true }) { 1 } else { 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionAbortExpression (then branch)
    fun if_then_abort(c: bool) {
        if (c) abort 1 else 2
    }

    // PAIR: IfExpression -> HiddenExpressionAssignExpression (then branch)
    fun if_then_assign(c: bool) {
        let x;
        if (c) x = 1 else 2
    }

    // PAIR: IfExpression -> HiddenExpressionLambdaExpression (then branch)
    fun if_then_lambda(c: bool) {
        if (c) |x| x else |y| y
    }

    // PAIR: IfExpression -> HiddenExpressionLoopExpression (then branch)
    fun if_then_loop(c: bool) {
        if (c) loop { break 1 } else 2
    }

    // PAIR: IfExpression -> HiddenExpressionMatchExpression (then branch)
    fun if_then_match(c: bool, x: u64) {
        if (c) match (x) { _ => 1 } else 2
    }

    // PAIR: IfExpression -> HiddenExpressionQuantifierExpression (then branch)
    spec fun if_then_quantifier(c: bool) {
        if (c) forall x: u64: x > 0 else false
    }

    // PAIR: IfExpression -> HiddenExpressionReturnExpression (then branch)
    fun if_then_return(c: bool) {
        if (c) return 1 else 2
    }

    // PAIR: IfExpression -> HiddenExpressionVectorExpression (then branch)
    fun if_then_vector(c: bool) {
        if (c) vector[1] else vector[2]
    }

    // PAIR: IfExpression -> HiddenExpressionWhileExpression (then branch)
    fun if_then_while(c: bool) {
        if (c) while (true) { break 1 } else 2
    }

    // PAIR: IfExpression -> HiddenExpressionAbortExpression (else branch)
    fun if_else_abort(c: bool) {
        if (c) 1 else abort 2
    }

    // PAIR: IfExpression -> HiddenExpressionAssignExpression (else branch)
    fun if_else_assign(c: bool) {
        let x;
        if (c) 1 else x = 2
    }

    // PAIR: IfExpression -> HiddenExpressionLambdaExpression (else branch)
    fun if_else_lambda(c: bool) {
        if (c) |x| x else |y| y
    }

    // PAIR: IfExpression -> HiddenExpressionLoopExpression (else branch)
    fun if_else_loop(c: bool) {
        if (c) 1 else loop { break 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionMatchExpression (else branch)
    fun if_else_match(c: bool, x: u64) {
        if (c) 1 else match (x) { _ => 2 }
    }

    // PAIR: IfExpression -> HiddenExpressionQuantifierExpression (else branch)
    spec fun if_else_quantifier(c: bool) {
        if (c) true else forall x: u64: x > 0
    }

    // PAIR: IfExpression -> HiddenExpressionReturnExpression (else branch)
    fun if_else_return(c: bool) {
        if (c) 1 else return 2
    }

    // PAIR: IfExpression -> HiddenExpressionVectorExpression (else branch)
    fun if_else_vector(c: bool) {
        if (c) vector[1] else vector[2]
    }

    // PAIR: IfExpression -> HiddenExpressionWhileExpression (else branch)
    fun if_else_while(c: bool) {
        if (c) 1 else while (true) { break 2 }
    }
}
