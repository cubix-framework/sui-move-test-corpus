// Synthetic test file for binding pattern node pairs
// Covers: CommaBindList, AtBind, BindField variants

module synthetic::binding_patterns {

    struct Foo { x: u64, y: u64 }

    // PAIR: CommaBindList -> HiddenBindAtBind
    fun comma_bind_with_at_bind(val: (Foo, u64)) {
        let (x @ Foo { y }, z) = val;
    }

    // PAIR: CommaBindList -> HiddenBindLiteralValue
    fun comma_bind_with_literal(val: (u64, u64)) {
        let (0x1, x) = val;
    }

    // PAIR: AtBind -> BindListCommaBindList
    fun at_bind_with_comma_list(v: (u64, u64)) {
        match (v) { x @ (a, b) => a + b }
    }

    // PAIR: BindField1 -> BindListCommaBindList
    fun bind_field_with_comma_list(x: u64) {
        Struct { (a, b): x }
    }
}
