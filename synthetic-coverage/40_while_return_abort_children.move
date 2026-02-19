// Synthetic test file for while/return/abort/if as children in various contexts
// Covers: WhileExpression, ReturnExpression, AbortExpression, IfExpression as children

module synthetic::while_return_abort_children {

    // === WhileExpression as direct child in various parents ===

    // PAIR: ArgList -> HiddenExpressionWhileExpression
    fun arg_while() {
        foo(while (true) { break });
    }

    // PAIR: BreakExpression -> HiddenExpressionWhileExpression
    fun break_while() {
        loop { break while (true) { break } };
    }

    // PAIR: ExpField -> HiddenExpressionWhileExpression
    fun expfield_while() {
        Foo { x: while (true) { break } };
    }

    // PAIR: IfExpression -> HiddenExpressionWhileExpression (while as if body, no braces)
    fun if_while_body() {
        if (true) while (false) { break } else 0;
    }

    // PAIR: LambdaExpression -> HiddenExpressionWhileExpression
    fun lambda_while() {
        let _ = |x: u64| while (true) { break };
    }

    // PAIR: LoopExpression -> HiddenExpressionWhileExpression (loop body = while)
    fun loop_while() {
        loop while (true) { break };
    }

    // PAIR: MatchArm -> HiddenExpressionWhileExpression
    fun matcharm_while(x: u64) {
        match (x) { _ => while (false) { break } };
    }

    // PAIR: MatchExpression -> HiddenExpressionWhileExpression
    fun matchexpr_while() {
        match (while (false) { break 0u64 }) { _ => 0 };
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionWhileExpression
    fun move_while() {
        move while (true) { break };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionWhileExpression
    spec fun qb2_while() {
        let _ = forall x in while (false) { break 0u64 }: x > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionWhileExpression
    spec fun qexpr_while() {
        let _ = forall x: u64: while (false) { break x };
    }

    // PAIR: UnaryExpression -> HiddenExpressionWhileExpression
    fun unary_while() {
        !while (true) { break };
    }

    // PAIR: WhileExpression -> HiddenExpressionWhileExpression (while body = while, no braces)
    fun while_while() {
        while (true) while (false) { break };
    }

    // === ReturnExpression as direct child ===

    // PAIR: BreakExpression -> HiddenExpressionReturnExpression
    fun break_return() {
        loop { break return 5 };
    }

    // PAIR: ExpField -> HiddenExpressionReturnExpression
    fun expfield_return() {
        Foo { x: return 5 };
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionReturnExpression
    fun identified_return() {
        'lab: return 5
    }

    // PAIR: IndexExpression -> HiddenExpressionReturnExpression (return in index position)
    fun index_return(v: vector<u64>) {
        v[return 0];
    }

    // PAIR: MatchExpression -> HiddenExpressionReturnExpression (return as match scrutinee)
    fun matchexpr_return(x: u64) {
        match (return 0) { _ => x };
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionReturnExpression
    fun move_return() {
        move return 5;
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionReturnExpression
    spec fun qb2_return() {
        let _ = forall i in return 0: i > 0;
    }

    // PAIR: QuantifierExpression -> HiddenExpressionReturnExpression
    spec fun qexpr_return() {
        let _ = forall x: u64: return x > 0;
    }

    // PAIR: UnaryExpression -> HiddenExpressionReturnExpression
    fun unary_return() {
        !return true;
    }

    // === AbortExpression as direct child ===

    // PAIR: MatchCondition -> HiddenExpressionAbortExpression
    fun matchcond_abort(x: u64) {
        match (x) { y if (abort 0) => y, _ => 0 };
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionAbortExpression
    spec fun qb2_abort() {
        let _ = forall x in abort 0: x > 0;
    }

    // PAIR: SpecApply -> HiddenExpressionAbortExpression
    spec module {
        apply abort 0 to foo;
    }

    // PAIR: UnaryExpression -> HiddenExpressionAbortExpression
    fun unary_abort() {
        !abort 0;
    }

    // PAIR: WhileExpression -> HiddenExpressionAbortExpression (while body = abort)
    fun while_abort() {
        while (true) abort 0;
    }

    // PAIR: WhileExpression -> HiddenExpressionMacroCallExpression (while body = macro call)
    fun while_macro() {
        while (true) assert!(false, 0);
    }

    // === IfExpression as direct child in binary expressions ===

    // PAIR: BinaryExpression5 -> HiddenExpressionIfExpression (0 != if ...)
    fun binop5_if(c: bool) {
        0u64 != if (c) { 1u64 } else { 2u64 };
    }

    // PAIR: BinaryExpression6 -> HiddenExpressionIfExpression (0 < if ...)
    fun binop6_if(c: bool) {
        0u64 < if (c) { 1u64 } else { 2u64 };
    }

    // PAIR: BinaryExpression11 -> HiddenExpressionIfExpression (1 | if ...)
    fun binop11_if(c: bool, x: u64) {
        1u64 | if (c) { x } else { 0 };
    }

    // PAIR: BinaryExpression12 -> HiddenExpressionIfExpression (1 ^ if ...)
    fun binop12_if(c: bool, x: u64) {
        1u64 ^ if (c) { x } else { 0 };
    }

    // PAIR: MatchCondition -> HiddenExpressionIfExpression
    fun matchcond_if(x: u64, c: bool) {
        match (x) { y if (if (c) { true } else { false }) => y, _ => 0 };
    }

    // PAIR: UnaryExpression -> HiddenExpressionIfExpression
    fun unary_if(c: bool) {
        !if (c) { true } else { false };
    }

    // PAIR: WhileExpression -> HiddenExpressionIfExpression (while body = if)
    fun while_if(c: bool) {
        while (true) if (c) { break } else { break };
    }

    // === DotExpression term variants ===

    // PAIR: DotExpression -> HiddenExpressionTermIfExpression
    fun dot_if(b: bool) {
        let x = 1u64;
        x.if (b) { 1 } else { 2 };
    }

    // PAIR: DotExpression -> HiddenExpressionTermSpecBlock
    fun dot_spec_block2() {
        spec { }.f;
    }
}
