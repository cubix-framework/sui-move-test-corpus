// Synthetic test file for Use declaration node pairs
// Covers: UseFun, UseMember, UseModuleMember variants

module synthetic::use_declarations {

    // PAIR: UseFun -> HiddenTypeApplyType
    use fun my_fun as MyType.method;

    // PAIR: UseFun -> HiddenTypeFunctionType
    use fun my_fun as (|u64| -> u64).method;

    // PAIR: UseFun -> HiddenTypePrimitiveType
    use fun my_fun as u64.method;

    // PAIR: UseFun -> HiddenTypeRefType
    use fun my_fun as &u64.method;

    // PAIR: UseFun -> HiddenTypeTupleType
    use fun my_fun as (u64, bool).method;

    // PAIR: UseMember1 -> HiddenTypeApplyType
    use 0x1::module::{member as MyType};

    // PAIR: UseModuleMember -> ModuleAccess5
    use 0x1::module::MyModule::member;

    // PAIR: UseModuleMember -> ModuleAccess8
    use 0x2::othermodule::0x1::nested::member;

    // PAIR: UseModuleMembers2 -> ModuleAccess5
    use 0x1::module::{MyModule::member1, MyModule::member2};

    // PAIR: UseModuleMembers2 -> ModuleAccess8
    use 0x1::module::{0x2::nested::member1, 0x2::nested::member2};

    fun my_fun(_x: u64) {}
}
