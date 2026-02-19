// Synthetic test file for miscellaneous field and type annotation pairs
// Covers: FieldAnnotation, FunctionTypeParameters, PositionalFields, RefType, TupleType, etc.

module synthetic::misc_field_types {

    struct MyStruct { field: u64 }

    // PAIR: FieldAnnotation -> HiddenTypeFunctionType
    struct S1 {
        f: |u64| -> u64
    }

    // PAIR: FieldAnnotation -> HiddenTypeRefType
    struct S2 {
        f: &u64
    }

    // PAIR: FunctionTypeParameters -> HiddenTypeFunctionType
    fun higher_order(f: |u64| -> u64): u64 {
        f(1)
    }

    // PAIR: RefType -> HiddenTypeApplyType
    fun ref_apply_type(): &MyType {
        &my_value
    }

    // PAIR: RefType -> HiddenTypeFunctionType
    fun ref_function_type(): &(|u64| -> u64) {
        &my_fn
    }

    // PAIR: RefType -> HiddenTypePrimitiveType
    fun ref_primitive(): &u64 {
        &0
    }

    // PAIR: RefType -> HiddenTypeRefType
    fun ref_ref_type(): &&u64 {
        &&0
    }

    // PAIR: RefType -> HiddenTypeTupleType
    fun ref_tuple_type(): &(u64, bool) {
        &(1, true)
    }

    // PAIR: TupleType -> HiddenTypeApplyType
    fun tuple_apply_type(): (MyType, u64) {
        (my_value, 1)
    }

    // PAIR: TupleType -> HiddenTypeFunctionType
    fun tuple_function_type(): (|u64| -> u64, u64) {
        (my_fn, 1)
    }

    // PAIR: TupleType -> HiddenTypePrimitiveType
    fun tuple_primitive(): (u64, bool) {
        (1, true)
    }

    // PAIR: TupleType -> HiddenTypeRefType
    fun tuple_ref_type(): (&u64, u64) {
        (&0, 1)
    }

    // PAIR: TupleType -> HiddenTypeTupleType
    fun tuple_tuple_type(): ((u64, bool), u64) {
        ((1, true), 2)
    }

    // PAIR: PositionalFields -> HiddenExpressionAbortExpression
    fun positional_abort() {
        MyStruct(abort 1)
    }

    // PAIR: PositionalFields -> HiddenExpressionAssignExpression
    fun positional_assign() {
        let x;
        MyStruct(x = 5)
    }

    // PAIR: PositionalFields -> HiddenExpressionLambdaExpression
    fun positional_lambda() {
        MyStruct(|x| x)
    }

    // PAIR: PositionalFields -> HiddenExpressionLoopExpression
    fun positional_loop() {
        MyStruct(loop { break 1 })
    }

    // PAIR: PositionalFields -> HiddenExpressionMatchExpression
    fun positional_match(x: u64) {
        MyStruct(match (x) { _ => 1 })
    }

    // PAIR: PositionalFields -> HiddenExpressionQuantifierExpression
    spec fun positional_quantifier() {
        MyStruct(forall x: u64: x > 0)
    }

    // PAIR: PositionalFields -> HiddenExpressionReturnExpression
    fun positional_return() {
        MyStruct(return 5)
    }

    // PAIR: PositionalFields -> HiddenExpressionVectorExpression
    fun positional_vector() {
        MyStruct(vector[1, 2])
    }

    // PAIR: PositionalFields -> HiddenExpressionWhileExpression
    fun positional_while() {
        MyStruct(while (true) { break 1 })
    }

    // PAIR: MutBindField -> HiddenBindAtBind
    fun mut_bind_at_bind(s: MyStruct) {
        let MyStruct { mut x @ y } = s;
    }

    // PAIR: MutBindField -> HiddenBindLiteralValue
    fun mut_bind_literal(s: MyStruct) {
        let MyStruct { mut 42 } = s;
    }

    // PAIR: ExpField -> HiddenExpressionAbortExpression
    fun exp_field_abort() {
        MyStruct { field: abort 1 }
    }

    // PAIR: ExpField -> HiddenExpressionAssignExpression
    fun exp_field_assign() {
        let x;
        MyStruct { field: x = 5 }
    }

    // PAIR: ExpField -> HiddenExpressionLambdaExpression
    fun exp_field_lambda() {
        MyStruct { field: |x| x }
    }

    // PAIR: ExpField -> HiddenExpressionLoopExpression
    fun exp_field_loop() {
        MyStruct { field: loop { break 1 } }
    }

    // PAIR: ExpField -> HiddenExpressionMatchExpression
    fun exp_field_match(x: u64) {
        MyStruct { field: match (x) { _ => 1 } }
    }

    // PAIR: ExpField -> HiddenExpressionQuantifierExpression
    spec fun exp_field_quantifier() {
        MyStruct { field: forall x: u64: x > 0 }
    }

    // PAIR: ExpField -> HiddenExpressionReturnExpression
    fun exp_field_return() {
        MyStruct { field: return 5 }
    }

    // PAIR: ExpField -> HiddenExpressionVectorExpression
    fun exp_field_vector() {
        MyStruct { field: vector[1, 2] }
    }

    // PAIR: ExpField -> HiddenExpressionWhileExpression
    fun exp_field_while() {
        MyStruct { field: while (true) { break 1 } }
    }
}
