// Synthetic test file for Lambda-related node pairs
// Covers: LambdaExpression, LambdaBindings, LambdaBinding variants

module synthetic::lambda_expressions {

    // PAIR: LambdaBinding3 -> ColonTok (type annotation)
    fun lambda_binding_with_type() {
        |x: u64| x + 1
    }

    // PAIR: LambdaBinding3 -> HiddenBindAtBind
    fun lambda_binding_at_bind() {
        |x @ y| x
    }

    // PAIR: LambdaBinding3 -> HiddenBindLiteralValue
    fun lambda_binding_literal() {
        |0x1| 5
    }

    // PAIR: LambdaBinding3 -> HiddenTypeApplyType
    fun lambda_binding_apply_type() {
        |x: MyType| x
    }

    // PAIR: LambdaBinding3 -> HiddenTypeFunctionType
    fun lambda_binding_function_type() {
        |f: |u64| -> u64| f(1)
    }

    // PAIR: LambdaBinding3 -> HiddenTypePrimitiveType
    fun lambda_binding_primitive_type() {
        |x: u64| x
    }

    // PAIR: LambdaBinding3 -> HiddenTypeRefType
    fun lambda_binding_ref_type() {
        |x: &u64| *x
    }

    // PAIR: LambdaBinding3 -> HiddenTypeTupleType
    fun lambda_binding_tuple_type() {
        |x: (u64, bool)| x
    }

    // PAIR: LambdaBindingBind -> HiddenBindAtBind
    fun lambda_binding_bind_at() {
        |x @ Foo { y }| y
    }

    // PAIR: LambdaBindingBind -> HiddenBindLiteralValue
    fun lambda_binding_bind_literal() {
        |42| true
    }

    // PAIR: LambdaBindings -> LambdaBinding3
    fun lambda_bindings_with_type() {
        |x: u64, y: bool| x
    }

    // PAIR: ExpressionList -> HiddenExpressionLambdaExpression
    fun expression_list_lambda() {
        (|x| x, |y| y)
    }

    // PAIR: ExpressionList -> HiddenExpressionMatchExpression
    fun expression_list_match(x: u64) {
        (match (x) { _ => 0 }, 1)
    }

    // PAIR: ExpressionList -> HiddenExpressionVectorExpression
    fun expression_list_vector() {
        (vector[1], vector[2])
    }
}
