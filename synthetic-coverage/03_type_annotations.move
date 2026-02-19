// Synthetic test file for ApplyType node pairs
// Covers: ApplyType -> ModuleAccess variants

module synthetic::type_annotations {

    // PAIR: ApplyType -> ModuleAccess2 (@identifier variant)
    fun type_with_at_identifier() {
        let x: @owner = @0x1;
    }

    // PAIR: ApplyType -> ModuleAccess5 (module_id::member variant)
    fun type_with_module_member() {
        let x: MyModule::MyType = 0;
    }

    // PAIR: ApplyType -> ModuleAccess8 (address::module::member variant without type args)
    fun type_with_full_path() {
        let x: 0x1::vector::Vector = vector[];
    }

    // PAIR: ApplyType -> ModuleAccess9 (enum variant access)
    fun type_with_enum_variant() {
        let x: 0x1::option::Option::Some = 0;
    }

    // PAIR: ApplyType -> ModuleAccessMember (reserved identifier variant)
    fun type_with_reserved_identifier() {
        let x: spec = 0;
        let y: forall = 1;
        let z: exists = 2;
    }
}
