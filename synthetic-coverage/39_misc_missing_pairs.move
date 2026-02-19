// Synthetic test file for miscellaneous missing node pairs
// Covers: DotExpression->TermSpecBlock, ExpField->IdentifiedExpression,
//   HiddenBindLiteralValue variants, HiddenExpressionMatchExpression->MatchExpression,
//   HiddenExpressionTermIfExpression->IfExpression, HiddenExpressionVectorExpression->VectorExpression,
//   HiddenMacroSignature variants, HiddenUnaryExpressionInternal0ExpressionTerm->MacroCallExpression,
//   IdentifiedExpression variants, IndexExpression->TermPackExpression/TermSpecBlock,
//   LambdaBinding3 variants, LambdaExpression variants, LoopExpression variants,
//   MatchCondition variants, MatchExpression variants, MoveOrCopyExpression variants,
//   MutBindField, PositionalFields type pairs, QuantifierBinding2 variants,
//   QuantifierExpression variants, RefType, UnaryExpression variants,
//   VectorExpression variants, WhileExpression variants

module synthetic::misc_missing_pairs {

    struct MyStruct { field: u64 }
    struct Foo { x: u64 }

    // === DotExpression -> HiddenExpressionTermSpecBlock ===
    // PAIR: DotExpression -> HiddenExpressionTermSpecBlock
    fun dot_spec_block() {
        (spec {}).field
    }

    // === ExpField -> HiddenExpressionIdentifiedExpression ===
    // PAIR: ExpField -> HiddenExpressionIdentifiedExpression
    fun exp_field_identified() {
        MyStruct { field: 'a: 5 }
    }

    // === HiddenBindLiteralValue variants ===
    // PAIR: HiddenBindLiteralValue -> HiddenLiteralValueAddressLiteral
    fun bind_literal_address(x: address) {
        match (x) { @0x1 => 1, _ => 0 }
    }

    // PAIR: HiddenBindLiteralValue -> HiddenLiteralValueByteStringLiteral
    fun bind_literal_bytestring(x: vector<u8>) {
        match (x) { b"hello" => 1, _ => 0 }
    }

    // PAIR: HiddenBindLiteralValue -> HiddenLiteralValueHexStringLiteral
    fun bind_literal_hexstring(x: vector<u8>) {
        match (x) { x"AB" => 1, _ => 0 }
    }

    // PAIR: HiddenBindLiteralValue -> HiddenLiteralValueStringLiteral
    fun bind_literal_string(x: vector<u8>) {
        match (x) { "hello" => 1, _ => 0 }
    }

    // === Identity hidden wrappers ===
    // PAIR: HiddenExpressionMatchExpression -> MatchExpression
    fun hidden_match(x: u64): u64 {
        match (x) { 0 => 1, _ => 0 }
    }

    // PAIR: HiddenExpressionTermIfExpression -> IfExpression
    fun hidden_if(c: bool): u64 {
        if (c) 1 else 2
    }

    // PAIR: HiddenExpressionVectorExpression -> VectorExpression
    fun hidden_vector(): vector<u64> {
        vector[1, 2, 3]
    }

    // === HiddenMacroSignature variants ===
    // PAIR: HiddenMacroSignature -> Modifier1
    public macro fun public_macro!() {}

    // PAIR: HiddenMacroSignature -> ModifierEntry
    entry macro fun entry_macro!() {}

    // PAIR: HiddenMacroSignature -> ModifierNative
    native macro fun native_macro!();

    // === HiddenUnaryExpressionInternal0ExpressionTerm -> HiddenExpressionTermMacroCallExpression ===
    // PAIR: HiddenUnaryExpressionInternal0ExpressionTerm -> HiddenExpressionTermMacroCallExpression
    fun unary_macro_term() {
        // A macro call used as the LHS of an assign (goes through unary -> expression_term path)
        foo!() = 5
    }

    // === IdentifiedExpression missing variants ===
    // PAIR: IdentifiedExpression -> HiddenExpressionCallExpression
    fun identified_call() {
        'label: foo(1)
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionIdentifiedExpression
    fun identified_nested() {
        'a: 'b: x
    }

    // PAIR: IdentifiedExpression -> HiddenExpressionMacroCallExpression
    fun identified_macro() {
        'label: foo!(1)
    }

    // === IndexExpression missing term variants ===
    // PAIR: IndexExpression -> HiddenExpressionTermPackExpression
    fun index_pack(v: vector<MyStruct>) {
        v[MyStruct { field: 0 }]
    }

    // PAIR: IndexExpression -> HiddenExpressionTermSpecBlock
    fun index_spec_block(v: vector<u64>) {
        v[(spec {}).]
    }

    // === LambdaBinding3 missing variants ===
    // PAIR: LambdaBinding3 -> HiddenBindBindInternal0
    fun lambda_bind_internal() {
        |x: u64| x
    }

    // PAIR: LambdaBinding3 -> HiddenBindBindUnpack
    fun lambda_bind_unpack() {
        |Foo { x }: Foo| x
    }

    // === LambdaExpression missing body variants ===
    // PAIR: LambdaExpression -> HiddenExpressionLoopExpression
    fun lambda_body_loop() {
        |x| loop { break x }
    }

    // PAIR: LambdaExpression -> HiddenExpressionMatchExpression
    fun lambda_body_match(x: u64) {
        |x| match (x) { _ => 0 }
    }

    // PAIR: LambdaExpression -> HiddenExpressionQuantifierExpression
    spec fun lambda_body_quantifier() {
        |x| forall y: u64: y > 0
    }

    // PAIR: LambdaExpression -> HiddenExpressionVectorExpression
    fun lambda_body_vector() {
        |x| vector[x]
    }

    // PAIR: LambdaExpression -> HiddenExpressionWhileExpression
    fun lambda_body_while() {
        |x| while (x > 0) { break }
    }

    // PAIR: LambdaExpression -> HiddenTypeFunctionType
    fun lambda_return_function_type() {
        |x| -> |u64| -> u64 x
    }

    // === LoopExpression missing variants ===
    // PAIR: LoopExpression -> HiddenExpressionLoopExpression
    fun loop_body_loop() {
        loop loop { break 0 }
    }

    // PAIR: LoopExpression -> HiddenExpressionMacroCallExpression
    fun loop_body_macro() {
        loop my_macro!(x)
    }

    // === MatchCondition missing variants ===
    // PAIR: MatchCondition -> HiddenExpressionIdentifiedExpression
    fun match_cond_identified(x: u64) {
        match (x) { y if ('label: x + 1) => y, _ => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionIfExpression
    fun match_cond_if(x: u64) {
        match (x) { y if (if (true) true else false) => y, _ => 0 }
    }

    // PAIR: MatchCondition -> HiddenExpressionMacroCallExpression
    fun match_cond_macro(x: u64) {
        match (x) { y if (my_macro!(args)) => y, _ => 0 }
    }

    // === MatchExpression missing scrutinee variants ===
    // PAIR: MatchExpression -> HiddenExpressionBinaryExpression
    fun match_scrutinee_binary(x: u64, y: u64) {
        match (x + y) { _ => 0 }
    }

    // PAIR: MatchExpression -> HiddenExpressionIdentifiedExpression
    fun match_scrutinee_identified(x: u64) {
        match ('lbl: x) { _ => 0 }
    }

    // PAIR: MatchExpression -> HiddenExpressionIfExpression
    fun match_scrutinee_if(b: bool) {
        match (if (b) 1 else 2) { _ => 0 }
    }

    // PAIR: MatchExpression -> HiddenExpressionMacroCallExpression
    fun match_scrutinee_macro() {
        match (my_macro!(x)) { _ => 0 }
    }

    // === MoveOrCopyExpression missing variants ===
    // PAIR: MoveOrCopyExpression -> HiddenExpressionCallExpression
    fun copy_call(x: u64) {
        copy foo(x)
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionIdentifiedExpression
    fun copy_identified(x: u64) {
        copy 'my_label: x
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionIfExpression
    fun copy_if(c: bool) {
        copy if (c) 1 else 2
    }

    // PAIR: MoveOrCopyExpression -> HiddenExpressionMacroCallExpression
    fun copy_macro() {
        copy my_macro!(x)
    }

    // === MutBindField -> BindFieldSpreadOperator ===
    // PAIR: MutBindField -> BindFieldSpreadOperator
    fun mut_bind_spread(s: MyStruct) {
        match (s) { MyStruct { mut .. } => 1 }
    }

    // === PositionalFields type pairs ===
    // PAIR: PositionalFields -> HiddenTypeFunctionType
    struct FuncStruct(|u64| -> bool);

    // PAIR: PositionalFields -> HiddenTypeRefType
    struct RefStruct(&u64);

    // PAIR: PositionalFields -> HiddenTypeTupleType
    struct TupleStruct((u64, bool));

    // === QuantifierBinding2 missing variants ===
    // PAIR: QuantifierBinding2 -> HiddenExpressionCallExpression
    spec fun quant_bind_call() {
        forall x in get_range(): true
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionCastExpression
    spec fun quant_bind_cast() {
        forall x in v as u64: true
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionIdentifiedExpression
    spec fun quant_bind_identified() {
        forall x in 'lbl: some_expr: true
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionIfExpression
    spec fun quant_bind_if() {
        forall x in if (b) v1 else v2: true
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionMacroCallExpression
    spec fun quant_bind_macro() {
        forall x in foo!(arg): true
    }

    // PAIR: QuantifierBinding2 -> HiddenExpressionUnaryExpression
    spec fun quant_bind_unary() {
        forall x in !b: true
    }

    // === QuantifierExpression body missing variants ===
    // PAIR: QuantifierExpression -> HiddenExpressionCastExpression
    spec fun quant_body_cast() {
        forall x: u64: x as u128
    }

    // PAIR: QuantifierExpression -> HiddenExpressionIdentifiedExpression
    spec fun quant_body_identified() {
        forall x: u64: 'lbl: x + 1
    }

    // PAIR: QuantifierExpression -> HiddenExpressionIfExpression
    spec fun quant_body_if() {
        forall x: u64: if (x > 0) true else false
    }

    // PAIR: QuantifierExpression -> HiddenExpressionMacroCallExpression
    spec fun quant_body_macro() {
        forall x: u64: foo!(x)
    }

    // === UnaryExpression missing variants ===
    // PAIR: UnaryExpression -> HiddenExpressionIdentifiedExpression
    fun unary_identified() {
        !'label: x
    }

    // PAIR: UnaryExpression -> HiddenExpressionIfExpression
    fun unary_if(c: bool) {
        !if (c) true else false
    }

    // === VectorExpression missing variants ===
    // PAIR: VectorExpression -> HiddenExpressionIdentifiedExpression
    fun vector_identified(x: u64) {
        vector['a: x + 1]
    }

    // PAIR: VectorExpression -> HiddenExpressionIfExpression
    fun vector_if(c: bool) {
        vector[if (c) 1 else 2]
    }

    // PAIR: VectorExpressionInternal02 -> HiddenTypeFunctionType
    fun vector_type_function() {
        vector<|u64| -> bool>[]
    }

    // === WhileExpression missing condition variants ===
    // PAIR: WhileExpression -> HiddenExpressionIfExpression
    fun while_cond_if() {
        while (if (true) true else false) { break }
    }

    // PAIR: WhileExpression -> HiddenExpressionMacroCallExpression
    fun while_cond_macro() {
        while (my_macro!(x)) { break }
    }
}
