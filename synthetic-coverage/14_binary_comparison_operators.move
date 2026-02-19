// Synthetic test file for BinaryExpression4-9 (==, !=, <, >, <=, >= operators) node pairs
// Covers: BinaryExpression4/5/6/7/8/9 -> various HiddenExpression RHS types

module synthetic::binary_comparison_operators {

    // PAIR: BinaryExpression4 -> HiddenExpressionAbortExpression
    fun eq_abort(a: u64) {
        a == abort 0
    }

    // PAIR: BinaryExpression4 -> HiddenExpressionIdentifiedExpression
    fun eq_identified(a: u64, x: u64) {
        a == 'l: x
    }

    // PAIR: BinaryExpression4 -> HiddenExpressionLambdaExpression
    fun eq_lambda(a: u64) {
        a == |x| x
    }

    // PAIR: BinaryExpression4 -> HiddenExpressionLoopExpression
    fun eq_loop(a: u64) {
        a == loop { break 0 }
    }

    // PAIR: BinaryExpression4 -> HiddenExpressionMatchExpression
    fun eq_match(x: u64, y: u64) {
        match (x) { _ => 1 } == y
    }

    // PAIR: BinaryExpression4 -> HiddenExpressionQuantifierExpression
    spec fun eq_quantifier(a: u64) {
        ensures a == forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression4 -> HiddenExpressionVectorExpression
    fun eq_vector(v: vector<u64>) {
        vector[1, 2] == v
    }

    // PAIR: BinaryExpression4 -> HiddenExpressionWhileExpression
    fun eq_while(a: u64) {
        a == while (true) { break }
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionAbortExpression
    fun ne_abort(a: u64) {
        a != abort 0
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionIdentifiedExpression
    fun ne_identified(a: u64, x: u64) {
        a != 'l: x
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionIfExpression
    fun ne_if(c: bool) {
        if (c) 1 else 2 != 0
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionLambdaExpression
    fun ne_lambda(a: u64) {
        a != |x| x
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionLoopExpression
    fun ne_loop(a: u64) {
        a != loop { break 0 }
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionMacroCallExpression
    fun ne_macro(y: u64) {
        foo!(x) != y
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionMatchExpression
    fun ne_match(x: u64, y: u64) {
        match (x) { _ => 1 } != y
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionQuantifierExpression
    spec fun ne_quantifier(a: u64) {
        ensures a != forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionVectorExpression
    fun ne_vector(v: vector<u64>) {
        vector[1, 2] != v
    }

    // PAIR: BinaryExpression5 -> HiddenExpressionWhileExpression
    fun ne_while(a: u64) {
        a != while (true) { break }
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionAbortExpression
    fun lt_abort(a: u64) {
        a < abort 0
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionIdentifiedExpression
    fun lt_identified(a: u64, x: u64) {
        a < 'l: x
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionIfExpression
    fun lt_if(c: bool) {
        if (c) 1 else 2 < 3
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionLambdaExpression
    fun lt_lambda(a: u64) {
        a < |x| x
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionLoopExpression
    fun lt_loop(x: u64) {
        x < loop { break 1 }
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionMatchExpression
    fun lt_match(x: u64, y: u64) {
        x < match (y) { _ => 1 }
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionQuantifierExpression
    spec fun lt_quantifier(x: u64) {
        ensures x < forall i: u64: i > 0;
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionVectorExpression
    fun lt_vector(x: u64) {
        x < vector[1, 2]
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionWhileExpression
    fun lt_while(x: u64) {
        x < while (true) { break }
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionAbortExpression
    fun gt_abort(x: u64) {
        x > abort 5
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionIdentifiedExpression
    fun gt_identified(x: u64, y: u64) {
        x > 'label: y
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionIfExpression
    fun gt_if(x: u64) {
        x > if (true) { 1 } else { 2 }
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionLambdaExpression
    fun gt_lambda(x: u64) {
        x > |y| y
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionLoopExpression
    fun gt_loop(x: u64) {
        x > loop { break 1 }
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionMatchExpression
    fun gt_match(x: u64, y: u64) {
        x > match (y) { _ => 1 }
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionQuantifierExpression
    spec fun gt_quantifier(x: u64) {
        ensures x > forall i: u64: i > 0;
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionVectorExpression
    fun gt_vector(x: u64) {
        x > vector[1, 2]
    }

    // PAIR: BinaryExpression7 -> HiddenExpressionWhileExpression
    fun gt_while(x: u64) {
        x > while (true) { break }
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionAbortExpression
    fun le_abort(x: u64) {
        x <= abort 5
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionIdentifiedExpression
    fun le_identified(x: u64, y: u64) {
        x <= 'label: y
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionIfExpression
    fun le_if(x: u64) {
        x <= if (true) { 1 } else { 2 }
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionLambdaExpression
    fun le_lambda(x: u64) {
        x <= |y| y
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionLoopExpression
    fun le_loop(x: u64) {
        x <= loop { break 1 }
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionMatchExpression
    fun le_match(x: u64, y: u64) {
        x <= match (y) { _ => 1 }
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionQuantifierExpression
    spec fun le_quantifier(x: u64) {
        ensures x <= forall i: u64: i > 0;
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionVectorExpression
    fun le_vector(x: u64) {
        x <= vector[1, 2]
    }

    // PAIR: BinaryExpression8 -> HiddenExpressionWhileExpression
    fun le_while(x: u64) {
        x <= while (true) { break }
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionAbortExpression
    fun ge_abort(x: u64) {
        x >= abort 1
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionIdentifiedExpression
    fun ge_identified(x: u64, y: u64) {
        x >= 'label: y
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionIfExpression
    fun ge_if() {
        1 >= if (true) 2 else 3
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionLambdaExpression
    fun ge_lambda() {
        1 >= |x| x
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionLoopExpression
    fun ge_loop() {
        1 >= loop { break 2 }
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionMatchExpression
    fun ge_match(x: u64) {
        1 >= match (x) { _ => 2 }
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionQuantifierExpression
    spec fun ge_quantifier() {
        ensures 1 >= forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionVectorExpression
    fun ge_vector() {
        1 >= vector[2, 3]
    }

    // PAIR: BinaryExpression9 -> HiddenExpressionWhileExpression
    fun ge_while() {
        1 >= while (true) { break 2 }
    }
}
