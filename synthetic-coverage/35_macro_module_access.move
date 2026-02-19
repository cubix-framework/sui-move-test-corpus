// Synthetic test file for Macro and ModuleAccess node pairs
// Covers: MacroModuleAccess, MacroFunctionDefinition, NameExpression variants

module synthetic::macro_module_access {

    // PAIR: MacroFunctionDefinition -> ModifierNative
    public macro fun native_macro!() {
        native
    }

    // PAIR: MacroModuleAccess -> ModuleAccess1 (plain identifier)
    fun macro_simple() {
        foo!()
    }

    // PAIR: MacroModuleAccess -> ModuleAccess2 (@identifier)
    fun macro_at_identifier() {
        @owner!()
    }

    // PAIR: MacroModuleAccess -> ModuleAccess5 (module_id::member)
    fun macro_module_member() {
        MyModule::foo!()
    }

    // PAIR: MacroModuleAccess -> ModuleAccess6 (module_id<type_args>::member)
    fun macro_module_type_args() {
        MyModule<u64>::foo!()
    }

    // PAIR: MacroModuleAccess -> ModuleAccess8 (address::module::member)
    fun macro_full_path() {
        0x1::debug::print!()
    }

    // PAIR: MacroModuleAccess -> ModuleAccess9 (enum variant)
    fun macro_enum_variant() {
        0x1::option::Option::Some!()
    }

    // PAIR: MacroModuleAccess -> ModuleAccessMember (reserved identifier)
    fun macro_reserved() {
        spec!()
    }

    // PAIR: NameExpression -> ModuleAccess2 (@identifier)
    fun name_at_identifier() {
        @owner
    }

    // PAIR: NameExpression -> ModuleAccess5 (module_id::member)
    fun name_module_member() {
        MyModule::member
    }

    // PAIR: NameExpression -> ModuleAccess6 (module_id<type_args>::member)
    fun name_module_type_args() {
        MyModule<u64>::member
    }

    // PAIR: NameExpression -> ModuleAccess8 (address::module::member)
    fun name_full_path() {
        0x1::module::member
    }

    // PAIR: NameExpression -> ModuleAccess9 (enum variant)
    fun name_enum_variant() {
        0x1::option::Option::Some
    }

    // PAIR: NameExpression -> ModuleAccessMember (reserved identifier)
    fun name_reserved() {
        spec
    }

    // PAIR: ModuleAccess5 -> HiddenTypeApplyType (in type position)
    fun module_access5_type(): MyModule::MyType {
        0
    }

    // PAIR: ModuleAccess8 -> HiddenTypeApplyType (in type position)
    fun module_access8_type(): 0x1::module::MyType {
        0
    }

    // PAIR: ModuleAccess9 -> HiddenTypeApplyType (in type position)
    fun module_access9_type(): 0x1::option::Option::Some {
        0
    }
}
