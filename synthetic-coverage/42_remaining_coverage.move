// Synthetic test file for remaining zero-coverage pairs
// Covers: quantifier as child of various parents, MatchCondition special cases,
//   UseModuleMember->UseMember1, MacroModuleAccess->ModuleAccess1/6,
//   QB2->QuantifierExpression

module synthetic::remaining_coverage {

    // === Quantifier as child of various parent expressions ===

    // PAIR: ExpField -> HiddenExpressionQuantifierExpression
    fun exp_field_quantifier() {
        Foo { x: forall y: u64: y > 0 };
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionQuantifierExpression
    fun identified_quantifier() {
        'lab: forall y: u64: y > 0
    }

    // PAIR: IfExpression -> HiddenExpressionQuantifierExpression
    fun if_quantifier() {
        if (true) forall y: u64: y > 0 else true
    }

    // PAIR: LetStatement -> HiddenExpressionQuantifierExpression
    fun let_quantifier() {
        let _x = forall y: u64: y > 0;
    }

    // PAIR: LoopExpression -> HiddenExpressionQuantifierExpression
    fun loop_quantifier() {
        loop forall y: u64: y > 0
    }

    // PAIR: MatchArm -> HiddenExpressionQuantifierExpression
    fun matcharm_quantifier(x: u64) {
        match (x) { _ => forall y: u64: y > 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionQuantifierExpression
    fun matchcond_quantifier(x: u64) {
        match (x) { y if (forall z: u64: z > 0) => y, _ => 0 }
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionQuantifierExpression
    fun move_quantifier() {
        move forall y: u64: y > 0
    }

    // PAIR: UnaryExpression -> HiddenExpressionQuantifierExpression
    fun unary_quantifier() {
        !forall y: u64: y > 0
    }

    // PAIR: VectorExpression -> HiddenExpressionQuantifierExpression
    fun vector_quantifier() {
        vector[forall y: u64: y > 0]
    }

    // PAIR: WhileExpression -> HiddenExpressionQuantifierExpression
    fun while_quantifier() {
        while (true) forall y: u64: y > 0
    }

    // === QuantifierBinding2 -> HiddenExpressionQuantifierExpression ===
    // Using spec module invariant context with nested quantifier as range expression
    spec module {
        // PAIR: QuantifierBinding2 -> HiddenExpressionQuantifierExpression
        invariant forall i in exists j: u64: j > 0: true;
    }

    fun sentinel_qb2_quantifier() {}

    // === BorrowExpression/DereferenceExpression/BreakExpression -> QuantifierExpression ===

    // PAIR: BorrowExpression -> HiddenExpressionQuantifierExpression
    fun borrow_quantifier() {
        & forall x: u64: x > 0
    }

    // PAIR: DereferenceExpression -> HiddenExpressionQuantifierExpression
    fun deref_quantifier() {
        * forall x: u64: x > 0
    }

    // PAIR: BreakExpression -> HiddenExpressionQuantifierExpression
    fun break_quantifier() {
        loop { break forall x: u64: x > 0 }
    }

    // === MatchCondition special cases ===

    // PAIR: MatchCondition -> HiddenExpressionCastExpression
    fun matchcond_cast(x: u64) {
        match (x) { y if (x as bool) => y, _ => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionLambdaExpression
    fun matchcond_lambda(x: u64) {
        match (x) { y if (|z: u64| z > 0)(y) => y, _ => 0 }
    }

    // === UseModuleMember -> UseMember1 ===
    // use module::submod::{item} produces UseModuleMember -> UseMember1
    use 0x1::module::submod::{item1, item2};

    fun sentinel_use() {}

    // === MacroModuleAccess -> ModuleAccess1 ===
    // $f!() in a macro body - calling a macro variable as macro
    macro fun apply_macro!($f: |u64| -> bool, $x: u64): bool {
        $f!($x)
    }

    // === MacroModuleAccess -> ModuleAccess6 ===
    // 0x1::module::member<TypeArgs>!() - macro call with type args
    fun mac_with_type_args() {
        0x1::debug::print<u64>!(&1u64)
    }
}
