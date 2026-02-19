// Synthetic test file for BinaryExpression1 (==> implies operator) node pairs
// Covers: BinaryExpression1 -> various HiddenExpression RHS types
// Note: ==> is a spec-only operator

module synthetic::binary_implies_operator {

    // PAIR: BinaryExpression1 -> HiddenExpressionAbortExpression
    spec fun implies_abort(a: bool, b: u64) {
        ensures a ==> abort b;
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionCastExpression
    spec fun implies_cast(a: bool, b: u8) {
        ensures a ==> b as u64;
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionIdentifiedExpression
    spec fun implies_identified(a: bool, b: u64) {
        ensures a ==> 'lbl: b;
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionIfExpression
    spec fun implies_if(a: bool) {
        ensures a ==> if (true) 1 else 2;
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionLambdaExpression
    spec fun implies_lambda(a: bool) {
        ensures a ==> |x| x + 1;
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionLoopExpression
    spec fun implies_loop(a: bool) {
        ensures a ==> loop { break };
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionMacroCallExpression
    spec fun implies_macro(a: bool) {
        ensures a ==> assert!(true);
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionMatchExpression
    spec fun implies_match(a: bool, x: u64) {
        ensures a ==> match (x) { y => true };
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionQuantifierExpression
    spec fun implies_quantifier(a: bool) {
        ensures a ==> forall x: u64: x > 0;
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionReturnExpression
    spec fun implies_return(a: bool, b: u64) {
        ensures a ==> return b;
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionVectorExpression
    spec fun implies_vector(a: bool) {
        ensures a ==> vector[1, 2];
    }

    // PAIR: BinaryExpression1 -> HiddenExpressionWhileExpression
    spec fun implies_while(a: bool) {
        ensures a ==> while (true) { break };
    }
}
