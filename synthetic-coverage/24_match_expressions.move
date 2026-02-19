// Synthetic test file for Match-related node pairs
// Covers: MatchExpression, MatchArm, MatchCondition variants

module synthetic::match_expressions {

    // PAIR: MatchArm -> HiddenExpressionCastExpression
    fun match_arm_cast(x: u64, y: u8) {
        match (x) { _ => y as u64 }
    }

    // PAIR: MatchArm -> HiddenExpressionLambdaExpression
    fun match_arm_lambda(x: u64) {
        match (x) { _ => |y| y }
    }

    // PAIR: MatchArm -> HiddenExpressionLoopExpression
    fun match_arm_loop(x: u64) {
        match (x) { _ => loop { break 1 } }
    }

    // PAIR: MatchArm -> HiddenExpressionMatchExpression
    fun match_arm_match(x: u64, y: u64) {
        match (x) { _ => match (y) { _ => 0 } }
    }

    // PAIR: MatchArm -> HiddenExpressionQuantifierExpression
    spec fun match_arm_quantifier(x: u64) {
        match (x) { _ => forall y: u64: y > 0 }
    }

    // PAIR: MatchArm -> HiddenExpressionVectorExpression
    fun match_arm_vector(x: u64) {
        match (x) { _ => vector[1, 2] }
    }

    // PAIR: MatchArm -> HiddenExpressionWhileExpression
    fun match_arm_while(x: u64) {
        match (x) { _ => while (true) { break 1 } }
    }

    // PAIR: MatchCondition -> HiddenExpressionAbortExpression
    // match_condition is: if ( _expression ) — parentheses required by grammar
    fun match_condition_abort(x: u64) {
        match (x) { y if (abort 1) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionAssignExpression
    fun match_condition_assign(x: u64) {
        let z;
        match (x) { y if (z = 5) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionCastExpression
    fun match_condition_cast(x: u64, w: u8) {
        match (x) { y if (w as u64) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionIdentifiedExpression
    fun match_condition_identified(x: u64) {
        match (x) { y if ('label: x + 1) => y, _ => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionIfExpression
    fun match_condition_if(x: u64) {
        match (x) { y if (if (true) true else false) => y, _ => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionLambdaExpression
    fun match_condition_lambda(x: u64) {
        match (x) { y if (|z| z) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionLoopExpression
    fun match_condition_loop(x: u64) {
        match (x) { y if (loop { break true }) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionMacroCallExpression
    fun match_condition_macro(x: u64) {
        match (x) { y if (my_macro!(args)) => y, _ => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionMatchExpression
    fun match_condition_match(x: u64, w: u64) {
        match (x) { y if (match (w) { _ => true }) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionQuantifierExpression
    spec fun match_condition_quantifier(x: u64) {
        match (x) { y if (forall z: u64: z > 0) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionReturnExpression
    fun match_condition_return(x: u64) {
        match (x) { y if (return true) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionVectorExpression
    fun match_condition_vector(x: u64) {
        match (x) { y if (vector[true]) => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionWhileExpression
    fun match_condition_while(x: u64) {
        match (x) { y if (while (true) { break true }) => 0 }
    }

    // PAIR: MatchExpression -> HiddenExpressionAbortExpression
    fun match_scrutinee_abort() {
        match (abort 0) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionAssignExpression
    fun match_scrutinee_assign() {
        let x;
        match (x = 5) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionIdentifiedExpression
    fun match_scrutinee_identified(x: u64) {
        match ('lbl: x) { _ => 0 }
    }

    // PAIR: MatchExpression -> HiddenExpressionIfExpression
    fun match_scrutinee_if(b: bool) {
        match (if (b) 1 else 2) { _ => 0 }
    }

    // PAIR: MatchExpression -> HiddenExpressionLambdaExpression
    fun match_scrutinee_lambda() {
        match (|x| x) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionLoopExpression
    fun match_scrutinee_loop() {
        match (loop { break 1 }) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionMatchExpression
    fun match_scrutinee_match(y: u64) {
        match (match (y) { _ => 0 }) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionQuantifierExpression
    spec fun match_scrutinee_quantifier() {
        match (forall x: u64: x > 0) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionReturnExpression
    fun match_scrutinee_return() {
        match (return 5) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionVectorExpression
    fun match_scrutinee_vector() {
        match (vector[1, 2]) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionWhileExpression
    fun match_scrutinee_while() {
        match (while (true) { break 1 }) { _ => 1 }
    }

    // PAIR: MatchExpression -> HiddenExpressionBinaryExpression
    fun match_scrutinee_binary(x: u64, y: u64) {
        match (x + y) { _ => 0 }
    }
}
