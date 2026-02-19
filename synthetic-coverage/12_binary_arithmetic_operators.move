// Synthetic test file for BinaryExpression16-20 (+, -, *, /, % operators) node pairs
// Covers: BinaryExpression16/17/18/19/20 -> various HiddenExpression RHS types

module synthetic::binary_arithmetic_operators {

    // PAIR: BinaryExpression16 -> HiddenExpressionLambdaExpression
    fun add_lambda(a: u64) {
        a + |x| x
    }

    // PAIR: BinaryExpression16 -> HiddenExpressionMatchExpression
    fun add_match(a: u64, x: u64) {
        a + match (x) { _ => 1 }
    }

    // PAIR: BinaryExpression16 -> HiddenExpressionQuantifierExpression
    spec fun add_quantifier(a: u64) {
        ensures a + forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression16 -> HiddenExpressionVectorExpression
    fun add_vector(a: u64) {
        a + vector[1, 2]
    }

    // PAIR: BinaryExpression16 -> HiddenExpressionWhileExpression
    fun add_while(a: u64) {
        a + while (true) { break 1 }
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionAbortExpression
    fun sub_abort(a: u64) {
        a - abort 1
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionIdentifiedExpression
    fun sub_identified(a: u64, x: u64) {
        a - 'lbl: x
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionIfExpression
    fun sub_if(a: u64) {
        a - if (true) 1 else 2
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionLambdaExpression
    fun sub_lambda(a: u64) {
        a - |x| x
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionLoopExpression
    fun sub_loop(a: u64) {
        a - loop { break 1 }
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionMatchExpression
    fun sub_match(a: u64, x: u64) {
        a - match (x) { _ => 1 }
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionQuantifierExpression
    spec fun sub_quantifier(a: u64) {
        ensures a - forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionVectorExpression
    fun sub_vector(a: u64) {
        a - vector[1, 2]
    }

    // PAIR: BinaryExpression17 -> HiddenExpressionWhileExpression
    fun sub_while(a: u64) {
        a - while (true) { break 0 }
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionAbortExpression
    fun mul_abort(a: u64) {
        a * abort 1
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionIdentifiedExpression
    fun mul_identified(a: u64, b: u64) {
        a * 'lbl: b
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionLambdaExpression
    fun mul_lambda(a: u64) {
        a * |x| x
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionLoopExpression
    fun mul_loop(a: u64) {
        a * loop { break 0 }
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionMatchExpression
    fun mul_match(a: u64, x: u64) {
        a * match (x) { y => 0 }
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionQuantifierExpression
    spec fun mul_quantifier(a: u64) {
        ensures a * forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionReturnExpression
    fun mul_return(a: u64) {
        a * return 1
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionVectorExpression
    fun mul_vector(a: u64) {
        a * vector[1, 2]
    }

    // PAIR: BinaryExpression18 -> HiddenExpressionWhileExpression
    fun mul_while(a: u64) {
        a * while (true) { break 0 }
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionAbortExpression
    fun div_abort(a: u64) {
        a / abort 1
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionIdentifiedExpression
    fun div_identified(a: u64, b: u64) {
        a / 'lbl: b
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionLambdaExpression
    fun div_lambda(a: u64) {
        a / |x| x
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionLoopExpression
    fun div_loop(a: u64) {
        a / loop { break 1 }
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionMatchExpression
    fun div_match(a: u64, x: u64) {
        a / match (x) { y => 1 }
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionQuantifierExpression
    spec fun div_quantifier(a: u64) {
        ensures a / forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionVectorExpression
    fun div_vector(a: u64) {
        a / vector[1, 2]
    }

    // PAIR: BinaryExpression19 -> HiddenExpressionWhileExpression
    fun div_while(a: u64) {
        a / while (true) { break 1 }
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionAbortExpression
    fun mod_abort(a: u64, b: u64) {
        a % abort b
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionIdentifiedExpression
    spec fun mod_identified(a: u64, b: u64) {
        ensures a % 'label: b;
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionIfExpression
    fun mod_if(a: u64) {
        a % if (true) 1 else 2
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionLambdaExpression
    fun mod_lambda(a: u64) {
        a % |x| x
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionLoopExpression
    fun mod_loop(a: u64) {
        a % loop { break 1 }
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionMacroCallExpression
    fun mod_macro(a: u64, x: u64) {
        a % foo!(x)
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionMatchExpression
    fun mod_match(a: u64, x: u64) {
        a % match (x) { y => 1 }
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionQuantifierExpression
    spec fun mod_quantifier(a: u64) {
        ensures a % forall x: u64: x;
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionVectorExpression
    fun mod_vector(a: u64) {
        a % vector[1, 2]
    }

    // PAIR: BinaryExpression20 -> HiddenExpressionWhileExpression
    fun mod_while(a: u64) {
        a % while (true) { break }
    }
}
