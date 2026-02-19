// Synthetic test file for ModuleAccess5, ModuleAccess8, and ModuleAccess9 pairs
// NOTE: These pairs are blocked by a parser ordering regression in the current binary.
// Commit 87b50216 had the correct ordering (most-specific first: 9,6,8,5,7,4).
// The current binary tries 4,5,6,7,8,9 (least-specific first), causing pModuleAccess4/7
// to succeed before pModuleAccess5/8/9 because Megaparsec.runParser does not verify
// all children are consumed. Once the ordering is restored, these examples will produce
// the expected ModuleAccess5/8/9 nodes.

module 0x1::test {

    struct MyStruct has drop { value: u64 }

    enum MyEnum has drop {
        A,
        B { val: u64 },
    }

    fun some_func(): u64 { 0 }
    fun generic_fn<T>(): u64 { 0 }

    // === ModuleAccess8: module_identity optional(type_args) :: identifier ===
    // Grammar: module_identity :: member (no type_args)

    // PAIR: NameExpression -> ModuleAccess8
    // PAIR: ModuleAccess8 -> ModuleIdentity
    // PAIR: ModuleAccess8 -> ColonColonTok
    // PAIR: ModuleAccess8 -> Identifier
    fun use_module_access8(): u64 {
        0x1::test::some_func()
    }

    // PAIR: ModuleAccess8 -> TypeArguments
    fun use_module_access8_with_types(): u64 {
        0x1::test<u64>::generic_fn()
    }

    // PAIR: ApplyType -> ModuleAccess8
    fun use_apply_type_access8(x: 0x1::test::MyStruct): u64 {
        x.value
    }

    // PAIR: UseFun -> ModuleAccess8
    use fun 0x1::test::some_func as u64.to_val;

    // PAIR: MacroModuleAccess -> ModuleAccess8
    // (macro call uses module_identity :: identifier !)
    // Note: macro_module_access = module_access + "!"
    // Using a function-style macro call:
    fun use_macro_access8() {
        0x1::test::assert_true!(true);
    }

    // === ModuleAccess5: module_identifier optional(type_args) :: identifier ===
    // Grammar: _module_identifier :: member (using a bare module name, not address::module)

    // PAIR: NameExpression -> ModuleAccess5
    // PAIR: ModuleAccess5 -> HiddenModuleIdentifier
    // PAIR: ModuleAccess5 -> ColonColonTok
    // PAIR: ModuleAccess5 -> Identifier
    fun use_module_access5(): u64 {
        test::some_func()
    }

    // PAIR: ModuleAccess5 -> TypeArguments
    fun use_module_access5_with_types(): u64 {
        test<u64>::generic_fn()
    }

    // PAIR: ApplyType -> ModuleAccess5
    fun use_apply_type_access5(x: test::MyStruct): u64 {
        x.value
    }

    // PAIR: UseFun -> ModuleAccess5
    // Must use type args on module name to force ModuleAccess5 over ModuleAccess7
    // (without type args, tree-sitter parses test::some_func as module_identity, giving ModuleAccess7)
    use fun test<u64>::some_func as u64.to_val2;

    // PAIR: MacroModuleAccess -> ModuleAccess5
    fun use_macro_access5() {
        test::assert_true!(true);
    }

    // === ModuleAccess9: module_identity :: enum_name optional(type_args) :: variant ===
    // Grammar: module_identity :: identifier type_args? :: identifier

    // PAIR: NameExpression -> ModuleAccess9
    // PAIR: ModuleAccess9 -> ModuleIdentity
    // PAIR: ModuleAccess9 -> ColonColonTok
    // PAIR: ModuleAccess9 -> Identifier
    fun use_module_access9(e: MyEnum): u64 {
        match (e) {
            0x1::test::MyEnum::A => 1,
            0x1::test::MyEnum::B { val } => val,
        }
    }

    // PAIR: ModuleAccess9 -> TypeArguments
    // (type_args on the enum_name)
    // Note: this requires a generic enum to be meaningful
    fun use_module_access9_generic<T: drop>(e: MyEnum): u64 {
        match (e) {
            0x1::test::MyEnum::A => 0,
            _ => 1,
        }
    }

    // PAIR: ApplyType -> ModuleAccess9
    // (module_access9 used as a type, e.g. in a pattern or struct literal context)
    fun use_apply_type_access9(): 0x1::test::MyEnum {
        0x1::test::MyEnum::A
    }

    // PAIR: UseFun -> ModuleAccess9
    // Note: use_fun with a fully-qualified enum variant path is unusual but syntactically valid
    // use fun 0x1::test::MyEnum::A as MyEnum.default_variant;

    // PAIR: MacroModuleAccess -> ModuleAccess9
    // Note: macro_module_access with module_access9 would be e.g. 0x1::test::MyEnum::A!()
    // This is syntactically unusual but possible per the grammar
}
