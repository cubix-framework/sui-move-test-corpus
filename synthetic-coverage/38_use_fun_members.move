// Synthetic test file for UseFun, UseMember, UseModuleMember, UseModuleMembers2 pairs
// Covers previously missing use-related node pairs

module synthetic::use_fun_members {

    // === UseFun with various ModuleAccess variants ===

    // PAIR: UseFun -> ModuleAccess2 (@identifier)
    use fun @owner as MyType.method;

    // PAIR: UseFun -> ModuleAccess5 (module_id::member)
    use fun MyModule::my_func as MyType.method;

    // PAIR: UseFun -> ModuleAccess6 (module_id<type_args>::member)
    use fun 0x2::module::func<T> as U.method;

    // PAIR: UseFun -> ModuleAccess8 (address::module::member)
    use fun 0x2::module::func as MyType.method;

    // PAIR: UseFun -> ModuleAccess9 (enum variant)
    use fun 0x2::module::MyEnum::Variant as MyType.method;

    // PAIR: UseFun -> ModuleAccessMember (reserved identifier)
    use fun exists as MyType.method;

    // === UseMember1, UseMember2 nesting pairs ===

    // PAIR: UseMember1 -> UseMember1 (nested use member)
    use 0x2::pkg::{sub1::{sub2::{A}}};

    // PAIR: UseMember1 -> UseMember2 (nested with path)
    use 0x2::pkg::{mod1::{sub::Item}};

    // PAIR: UseModuleMember -> UseMember1 (nested braces)
    use 0x2::module::{sub::{A, B}};

    // PAIR: UseModuleMember -> UseMember2 (path member)
    use 0x2::module::sub::Item;

    // PAIR: UseModuleMembers2 -> UseMember1 (nested list with braces)
    use 0x1::module::{nested::{Item}};

    // PAIR: UseModuleMembers2 -> UseMember2 (path in list)
    use 0x1::module::{other::Item};

    // === ModuleAccess5 structural pairs ===

    // PAIR: ModuleAccess5 -> ColonColonTok
    // PAIR: ModuleAccess5 -> HiddenModuleIdentifier
    // PAIR: ModuleAccess5 -> Identifier
    fun use_module_access5() {
        MyModule::my_function
    }

    // PAIR: ModuleAccess5 -> TypeArguments
    fun use_module_access5_type_args() {
        MyModule<u64>::my_function
    }

    // === ModuleAccess8 structural pairs ===

    // PAIR: ModuleAccess8 -> ColonColonTok
    // PAIR: ModuleAccess8 -> Identifier
    // PAIR: ModuleAccess8 -> ModuleIdentity
    fun use_module_access8() {
        0x1::coin::value
    }

    // PAIR: ModuleAccess8 -> TypeArguments
    fun use_module_access8_type_args() {
        0x1::option::Option<u64>::none
    }

    // === ModuleAccess9 structural pairs ===

    // PAIR: ModuleAccess9 -> ColonColonTok
    // PAIR: ModuleAccess9 -> Identifier
    // PAIR: ModuleAccess9 -> ModuleIdentity
    fun use_module_access9() {
        0x1::my_module::MyEnum::Variant
    }

    // PAIR: ModuleAccess9 -> TypeArguments
    fun use_module_access9_type_args() {
        0x1::my_module::MyEnum<u64>::Variant
    }

    // === NameExpression with ModuleAccess5, 8, 9 ===

    // PAIR: NameExpression -> ModuleAccess5
    fun name_expr_module5() {
        MyModule::my_function
    }

    // PAIR: NameExpression -> ModuleAccess8
    fun name_expr_module8() {
        0x1::coin::value
    }

    // PAIR: NameExpression -> ModuleAccess9
    fun name_expr_module9() {
        0x1::my_module::MyEnum::Variant
    }
}
