// Synthetic test file for DotExpression and IndexExpression node pairs
// Covers: DotExpression/IndexExpression -> various child expression types

module synthetic::dot_index_expressions {

    struct S { field: u64 }

    // PAIR: DotExpression -> HiddenExpressionTermIfExpression
    fun dot_if(c: bool) {
        if (c) { S { field: 1 } } else { S { field: 2 } }.field
    }

    // PAIR: IndexExpression -> HiddenExpressionAbortExpression
    fun index_abort(v: vector<u64>) {
        v[abort 0]
    }

    // PAIR: IndexExpression -> HiddenExpressionAssignExpression
    fun index_assign(v: vector<u64>) {
        let x;
        v[x = 0]
    }

    // PAIR: IndexExpression -> HiddenExpressionIdentifiedExpression
    fun index_identified(v: vector<u64>, x: u64) {
        v['lbl: x]
    }

    // PAIR: IndexExpression -> HiddenExpressionIfExpression
    fun index_if(v: vector<u64>, c: bool) {
        v[if (c) 0 else 1]
    }

    // PAIR: IndexExpression -> HiddenExpressionLambdaExpression
    fun index_lambda(v: vector<u64>) {
        v[|x| x]
    }

    // PAIR: IndexExpression -> HiddenExpressionLoopExpression
    fun index_loop(v: vector<u64>) {
        v[loop { break 0 }]
    }

    // PAIR: IndexExpression -> HiddenExpressionMacroCallExpression
    fun index_macro(v: vector<u64>) {
        v[foo!()]
    }

    // PAIR: IndexExpression -> HiddenExpressionMatchExpression
    fun index_match(v: vector<u64>, x: u64) {
        v[match (x) { _ => 0 }]
    }

    // PAIR: IndexExpression -> HiddenExpressionQuantifierExpression
    spec fun index_quantifier(v: vector<u64>) {
        v[forall x: u64: x > 0]
    }

    // PAIR: IndexExpression -> HiddenExpressionReturnExpression
    fun index_return(v: vector<u64>) {
        v[return 0]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermAnnotationExpression
    fun index_annotation(v: vector<u64>, x: u8) {
        v[(x as u64 : u64)]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermBlock
    fun index_block(v: vector<u64>) {
        v[{ 0 }]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermBreakExpression
    fun index_break(v: vector<u64>) {
        loop { v[break 0] }
    }

    // PAIR: IndexExpression -> HiddenExpressionTermContinueExpression
    fun index_continue(v: vector<u64>) {
        loop { v[continue] }
    }

    // PAIR: IndexExpression -> HiddenExpressionTermDotExpression
    fun index_dot(v: vector<S>) {
        let s = S { field: 0 };
        v[s.field]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermIfExpression
    fun index_if_term(v: vector<u64>, c: bool) {
        v[if (c) { 0 } else { 1 }]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermMacroCallExpression
    fun index_macro_term(v: vector<u64>) {
        v[bar!()]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermMatchExpression
    fun index_match_term(v: vector<u64>, x: u64) {
        v[match (x) { _ => 0 }]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermUnitExpression
    fun index_unit(v: vector<u64>) {
        v[()]
    }

    // PAIR: IndexExpression -> HiddenExpressionVectorExpression
    fun index_vector(v: vector<u64>) {
        v[vector[0, 1]]
    }

    // PAIR: IndexExpression -> HiddenExpressionWhileExpression
    fun index_while(v: vector<u64>) {
        v[while (true) { break 0 }]
    }
}
