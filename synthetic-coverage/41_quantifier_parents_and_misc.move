// Synthetic test file for quantifier parent expressions and miscellaneous pairs
// Covers: quantifier expression parents, macro signature modifiers,
//   IndexExpression terms, FunctionType, QuantifierBinding1, misc

module synthetic::quantifier_parents_and_misc {

    // === Quantifier as child (parent -> HiddenExpressionQuantifierExpression) ===

    // PAIR: ArgList -> HiddenExpressionQuantifierExpression
    spec fun arg_quantifier() {
        let _ = some_fun(forall x: u64: x > 0);
    }

    // PAIR: AssignExpression -> HiddenExpressionQuantifierExpression (x = forall...)
    fun assign_quantifier() {
        let mut x = false;
        x = forall y: u64: y > 0;
    }

    // PAIR: BlockItemInternal0Expression -> HiddenExpressionQuantifierExpression
    // (forall as an expression statement with semicolon in a block)
    fun block_item_quantifier() {
        let x = 1u64;
        forall y: u64: y > x;
        let _ = 0u64;
    }

    // PAIR: Constant -> HiddenExpressionQuantifierExpression
    const ALWAYS_TRUE: bool = forall x: u64: x >= 0;

    // PAIR: IndexExpression -> HiddenExpressionQuantifierExpression
    fun index_quantifier(v: vector<u64>) {
        v[forall x: u64: x > 0];
    }

    // PAIR: LambdaExpression -> HiddenExpressionQuantifierExpression (body = forall)
    spec fun lambda_quantifier() {
        let _ = |x: u64| forall y: u64: y > x;
    }

    // PAIR: MatchExpression -> HiddenExpressionQuantifierExpression (match scrutinee = forall)
    spec fun matchexpr_quantifier() {
        let _ = match (forall y: u64: y > 0) { _ => 0 };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionQuantifierExpression (nested quantifier)
    spec fun qb2_quantifier() {
        let _ = forall x in (forall y: u64: y > 0): x;
    }

    // === AssignExpression as child in various contexts ===

    // PAIR: MatchCondition -> HiddenExpressionAssignExpression
    fun matchcond_assign(x: u64) {
        let mut b = false;
        match (x) { y if (b = y > 0) => y, _ => 0 };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionAssignExpression
    spec fun qb2_assign() {
        let mut b = false;
        let _ = forall x in b = true: x;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionAssignExpression
    spec fun qexpr_assign() {
        let mut b = false;
        let _ = forall x: u64: b = x > 0;
    }

    // === IdentifiedExpression as child in various contexts ===

    // PAIR: MatchCondition -> HiddenExpressionIdentifiedExpression
    fun matchcond_identified(x: u64) {
        match (x) { y if ('lab: true) => y, _ => 0 };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionIdentifiedExpression
    spec fun qb2_identified() {
        let _ = forall x in 'lab: 0u64..10u64: x > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionIdentifiedExpression
    spec fun qexpr_identified() {
        let _ = forall x: u64: 'lab: x > 0;
    }

    // PAIR: UnaryExpression -> HiddenExpressionIdentifiedExpression
    fun unary_identified() {
        !'lab: true
    }

    // PAIR: VectorExpression -> HiddenExpressionIdentifiedExpression
    fun vector_identified() {
        vector['lab: 1u64, 2u64];
    }

    // === LambdaExpression as child in various contexts ===

    // PAIR: MatchCondition -> HiddenExpressionLambdaExpression
    fun matchcond_lambda(x: u64) {
        match (x) { y if ((|a: u64| a > 0)(y)) => y, _ => 0 };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionLambdaExpression
    spec fun qb2_lambda() {
        let _ = forall x in |a: u64| a: x > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionLambdaExpression
    spec fun qexpr_lambda() {
        let _ = forall x: u64: |a: u64| a > x;
    }

    // PAIR: UnaryExpression -> HiddenExpressionLambdaExpression
    fun unary_lambda() {
        !|x: bool| x
    }

    // === LoopExpression as child in various contexts ===

    // PAIR: LoopExpression -> HiddenExpressionLoopExpression (nested loop)
    fun loop_loop() {
        loop loop { break };
    }

    // PAIR: MatchCondition -> HiddenExpressionLoopExpression
    fun matchcond_loop(x: u64) {
        match (x) { y if (loop { break true }) => y, _ => 0 };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionLoopExpression
    spec fun qb2_loop() {
        let _ = forall x in loop { break 0u64..10u64 }: x > 0;
    }

    // PAIR: UnaryExpression -> HiddenExpressionLoopExpression
    fun unary_loop() {
        !loop { break true }
    }

    // === MacroCallExpression as child in various contexts ===

    // PAIR: LoopExpression -> HiddenExpressionMacroCallExpression (loop body = macro)
    fun loop_macro() {
        loop assert!(true, 0);
    }

    // PAIR: MatchCondition -> HiddenExpressionMacroCallExpression
    fun matchcond_macro(x: u64) {
        match (x) { y if (assert!(true, 0)) => y, _ => 0 };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionMacroCallExpression
    spec fun qb2_macro() {
        let _ = forall x in assert!(true, 0): x > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionMacroCallExpression
    spec fun qexpr_macro() {
        let _ = forall x: u64: assert!(x > 0, 0);
    }

    // === QuantifierExpression body variants ===

    // PAIR: QuantifierExpression -> HiddenExpressionLambdaExpression
    spec fun qexpr_lambda_body() {
        let _ = forall x: u64: |a: u64| a > x;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionReturnExpression
    spec fun qexpr_return_body() {
        let _ = forall x: u64: return x > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionWhileExpression
    spec fun qexpr_while_body() {
        let _ = forall x: u64: while (false) { break x };
    }

    // PAIR: QuantifierExpression -> HiddenExpressionAssignExpression
    spec fun qexpr_assign_body() {
        let mut b = false;
        let _ = forall x: u64: b = x > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionIdentifiedExpression
    spec fun qexpr_identified_body() {
        let _ = forall x: u64: 'lab: x > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionMacroCallExpression
    spec fun qexpr_macro_body() {
        let _ = forall x: u64: assert!(x > 0, 0);
    }

    // === QuantifierBinding1 -> HiddenTypeTupleType ===

    // PAIR: QuantifierBinding1 -> HiddenTypeTupleType
    spec fun qb1_tuple() {
        let _ = forall x: (u64, bool): true;
    }

    // === HiddenTypeFunctionType pairs ===

    // PAIR: FunctionTypeParameters -> HiddenTypeFunctionType (nested function type)
    fun functype_nested() {
        let _: ||u64| -> bool| = |f: |u64| -> bool| f(0);
    }

    // PAIR: LambdaExpression -> HiddenTypeFunctionType (lambda with function return type)
    fun lambda_functype() {
        let _: |u64| -> |u64| -> u64 = |x: u64| -> |u64| -> u64 |y: u64| x + y;
    }

    // PAIR: RefType -> HiddenTypeFunctionType (&|u64| -> bool)
    fun ref_functype() {
        let _: &|u64| -> bool = &|x: u64| x > 0;
    }

    // === IndexExpression -> HiddenExpressionTerm* variants ===

    // PAIR: IndexExpression -> HiddenExpressionTermAnnotationExpression
    fun index_annot(x: u64) {
        (x: u64)[0];
    }

    // PAIR: IndexExpression -> HiddenExpressionTermBlock
    fun index_block(v: vector<u64>) {
        { v }[0];
    }

    // PAIR: IndexExpression -> HiddenExpressionTermBreakExpression
    fun index_break() {
        loop { break[0] };
    }

    // PAIR: IndexExpression -> HiddenExpressionTermContinueExpression
    fun index_continue() {
        loop { continue[0] };
    }

    // PAIR: IndexExpression -> HiddenExpressionTermMacroCallExpression
    fun index_macro() {
        f!()[0];
    }

    // PAIR: IndexExpression -> HiddenExpressionTermMatchExpression
    fun index_match(x: u64, v: vector<u64>) {
        match (x) { _ => v }[0];
    }

    // PAIR: IndexExpression -> HiddenExpressionTermPackExpression
    fun index_pack(v: vector<u64>) {
        Foo { data: v }[0];
    }

    // PAIR: IndexExpression -> HiddenExpressionTermSpecBlock
    fun index_spec() {
        spec { }[0];
    }

    // PAIR: IndexExpression -> HiddenExpressionTermUnitExpression
    fun index_unit() {
        ()[0];
    }

    // === Misc pairs ===

    // PAIR: BindField1 -> BindListCommaBindList (tuple pattern in struct field)
    fun bind_field_tuple(x: (u64, bool)) {
        let S { (a, b): fld } = S { fld: x };
    }

    // PAIR: HiddenMacroSignature -> Modifier1 (macro public fun)
    macro public fun macro_public!() {
        1
    }

    // PAIR: HiddenMacroSignature -> ModifierEntry (macro entry fun)
    macro entry fun macro_entry!() {
        1
    }

    // PAIR: HiddenMacroSignature -> ModifierNative (macro native fun)
    macro native fun macro_native!() { 1 }

    // PAIR: SpecBlockInternal0SpecFunction -> HiddenSpecFunctionUninterpretedSpecFunction
    spec fun uninterpreted_spec(): u64;

    // PAIR: UseModuleMembers2 -> UseMember1 (nested use members)
    use 0x2::module::{sub::{A, B}};

    // PAIR: Block -> HiddenExpressionQuantifierExpression (quantifier as block return expr)
    spec fun block_quantifier(): bool {
        forall x: u64: x > 0
    }
}
