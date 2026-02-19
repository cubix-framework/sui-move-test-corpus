// Synthetic test file for Quantifier-related node pairs (spec-only)
// Covers: QuantifierExpression, QuantifierBinding variants

module synthetic::quantifier_expressions {

    // PAIR: QuantifierBinding1 -> HiddenTypeApplyType
    spec fun quantifier_binding_apply_type() {
        forall x: MyType: true
    }

    // PAIR: QuantifierBinding1 -> HiddenTypeFunctionType
    spec fun quantifier_binding_function_type() {
        forall f: |u64| -> u64: true
    }

    // PAIR: QuantifierBinding1 -> HiddenTypePrimitiveType
    spec fun quantifier_binding_primitive() {
        forall x: u64: x > 0
    }

    // PAIR: QuantifierBinding1 -> HiddenTypeRefType
    spec fun quantifier_binding_ref_type() {
        forall r: &u64: *r > 0
    }

    // PAIR: QuantifierBinding1 -> HiddenTypeTupleType
    spec fun quantifier_binding_tuple_type() {
        forall t: (u64, bool): true
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionAbortExpression
    spec fun quantifier_binding_where_abort() {
        forall x: u64 where abort 1: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionAssignExpression
    spec fun quantifier_binding_where_assign() {
        let y;
        forall x: u64 where y = 5: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionLambdaExpression
    spec fun quantifier_binding_where_lambda() {
        forall x: u64 where |y| y: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionLoopExpression
    spec fun quantifier_binding_where_loop() {
        forall x: u64 where loop { break true }: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionMatchExpression
    spec fun quantifier_binding_where_match(z: u64) {
        forall x: u64 where match (z) { _ => true }: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionQuantifierExpression
    spec fun quantifier_binding_where_quantifier() {
        forall x: u64 where exists y: u64: y > 0: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionReturnExpression
    spec fun quantifier_binding_where_return() {
        forall x: u64 where return true: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionVectorExpression
    spec fun quantifier_binding_where_vector() {
        forall x: u64 where vector[true]: x > 0
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionWhileExpression
    spec fun quantifier_binding_where_while() {
        forall x: u64 where while (true) { break true }: x > 0
    }

    // PAIR: QuantifierExpression -> HiddenExpressionAbortExpression
    spec fun quantifier_body_abort() {
        forall x: u64: abort 1
    }

    // PAIR: QuantifierExpression -> HiddenExpressionAssignExpression
    spec fun quantifier_body_assign() {
        let y;
        forall x: u64: y = 5
    }

    // PAIR: QuantifierExpression -> HiddenExpressionLambdaExpression
    spec fun quantifier_body_lambda() {
        forall x: u64: |y| y
    }

    // PAIR: QuantifierExpression -> HiddenExpressionLoopExpression
    spec fun quantifier_body_loop() {
        forall x: u64: loop { break true }
    }

    // PAIR: QuantifierExpression -> HiddenExpressionMatchExpression
    spec fun quantifier_body_match(z: u64) {
        forall x: u64: match (z) { _ => true }
    }

    // PAIR: QuantifierExpression -> HiddenExpressionQuantifierExpression
    spec fun quantifier_body_quantifier() {
        forall x: u64: exists y: u64: y > 0
    }

    // PAIR: QuantifierExpression -> HiddenExpressionReturnExpression
    spec fun quantifier_body_return() {
        forall x: u64: return true
    }

    // PAIR: QuantifierExpression -> HiddenExpressionVectorExpression
    spec fun quantifier_body_vector() {
        forall x: u64: vector[true]
    }

    // PAIR: QuantifierExpression -> HiddenExpressionWhileExpression
    spec fun quantifier_body_while() {
        forall x: u64: while (true) { break true }
    }
}
