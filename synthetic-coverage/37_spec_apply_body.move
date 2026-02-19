// Synthetic test file for SpecApply, SpecBody, SpecInclude, SpecInvariant, SpecLet, SpecVariable pairs
// Covers many previously missing spec-related pairs

module synthetic::spec_apply_body {

    fun target_fun(_x: u64): u64 { 0 }

    // === SpecApply pairs ===

    // PAIR: SpecApply -> ExceptTok
    spec module {
        apply target_fun to * except target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionAssignExpression
    spec module {
        apply x = 1 to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionBinaryExpression
    spec module {
        apply a + b to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionCallExpression
    spec module {
        apply f() to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionCastExpression
    spec module {
        apply x as u64 to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionIdentifiedExpression
    spec module {
        apply 'a: x to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionIfExpression
    spec module {
        apply if (c) t else f to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionLambdaExpression
    spec module {
        apply |x| x + 1 to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionLoopExpression
    spec module {
        apply loop { break 0 } to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionMacroCallExpression
    spec module {
        apply assert!(true) to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionMatchExpression
    spec module {
        apply match (x) { 0 => 1 } to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionQuantifierExpression
    spec module {
        apply forall x: u64: x > 0 to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionReturnExpression
    spec module {
        apply return 0 to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionUnaryExpression
    spec module {
        apply !cond to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionVectorExpression
    spec module {
        apply vector[1, 2] to target_fun;
    }

    // PAIR: SpecApply -> HiddenExpressionWhileExpression
    spec module {
        apply while (true) { break 0 } to target_fun;
    }

    // PAIR: SpecApply -> SemicolonTok
    // PAIR: SpecApply -> SpecApplyPattern
    // PAIR: SpecApplyPattern -> SpecApplyNamePattern
    spec module {
        apply MySchema to target_fun;
    }

    // PAIR: SpecApplyPattern -> SpecApplyPatternInternal0Internal
    // PAIR: SpecApplyPatternInternal0Internal -> InternalTok
    spec module {
        apply MySchema to internal target_fun;
    }

    // PAIR: SpecApplyPattern -> SpecApplyPatternInternal0Public
    // PAIR: SpecApplyPatternInternal0Public -> PublicTok
    spec module {
        apply MySchema to public target_fun;
    }

    // PAIR: SpecApplyPattern -> TypeParameters
    spec module {
        apply MySchema to target_fun<T>;
    }

    // === SpecBody pairs ===

    // PAIR: HiddenSpecBlockMemeberSpecApply -> SpecApply
    // PAIR: SpecBody -> HiddenSpecBlockMemeberSpecApply
    spec module {
        apply MySchema to target_fun;
    }

    // PAIR: SpecBody -> UseDeclaration
    spec module {
        use 0x1::option;
    }

    // PAIR: HiddenSpecBlockMemeberSpecFunction -> HiddenSpecFunctionUninterpretedSpecFunction
    // PAIR: SpecBlockInternal0SpecFunction -> HiddenSpecFunctionUninterpretedSpecFunction
    // PAIR: HiddenSpecFunctionUninterpretedSpecFunction -> UninterpretedSpecFunction
    spec module {
        fun uninterp_fn(x: u64): u64;
    }

    // PAIR: UninterpretedSpecFunction -> HiddenSpecFunctionSignature
    spec module {
        fun uninterp_fn2(x: u64): bool;
    }

    // === SpecInclude missing pairs ===

    // PAIR: SpecInclude -> HiddenExpressionBinaryExpression
    spec module {
        include a + b;
    }

    // PAIR: SpecInclude -> HiddenExpressionCallExpression
    spec module {
        include foo();
    }

    // PAIR: SpecInclude -> HiddenExpressionCastExpression
    spec module {
        include x as u64;
    }

    // PAIR: SpecInclude -> HiddenExpressionIdentifiedExpression
    spec module {
        include 'a: MySchema;
    }

    // PAIR: SpecInclude -> HiddenExpressionIfExpression
    spec module {
        include if (true) MySchema else OtherSchema;
    }

    // PAIR: SpecInclude -> HiddenExpressionMacroCallExpression
    spec module {
        include assert!(true);
    }

    // === SpecInvariant pairs ===

    // PAIR: SpecInvariant -> ConditionProperties
    spec module {
        invariant [global] x > 0;
    }

    // PAIR: SpecInvariant -> HiddenExpressionAbortExpression
    spec module {
        invariant abort 1;
    }

    // PAIR: SpecInvariant -> HiddenExpressionAssignExpression
    spec module {
        invariant x = 1;
    }

    // PAIR: SpecInvariant -> HiddenExpressionCastExpression
    spec module {
        invariant x as u64;
    }

    // PAIR: SpecInvariant -> HiddenExpressionIdentifiedExpression
    spec module {
        invariant 'label: x + 1;
    }

    // PAIR: SpecInvariant -> HiddenExpressionIfExpression
    spec module {
        invariant if (true) 1 else 2;
    }

    // PAIR: SpecInvariant -> HiddenExpressionLambdaExpression
    spec module {
        invariant |x| x + 1;
    }

    // PAIR: SpecInvariant -> HiddenExpressionLoopExpression
    spec module {
        invariant loop { break 0 };
    }

    // PAIR: SpecInvariant -> HiddenExpressionMacroCallExpression
    spec module {
        invariant assert!(true);
    }

    // PAIR: SpecInvariant -> HiddenExpressionMatchExpression
    spec module {
        invariant match (x) { 1 => true, _ => false };
    }

    // PAIR: SpecInvariant -> HiddenExpressionReturnExpression
    spec module {
        invariant return true;
    }

    // PAIR: SpecInvariant -> HiddenExpressionUnaryExpression
    spec module {
        invariant !false;
    }

    // PAIR: SpecInvariant -> HiddenExpressionVectorExpression
    spec module {
        invariant vector[true];
    }

    // PAIR: SpecInvariant -> HiddenExpressionWhileExpression
    spec module {
        invariant while (false) { break };
    }

    // PAIR: SpecInvariant -> SpecInvariantInternal0Module
    // PAIR: SpecInvariantInternal0Module -> ModuleTok
    spec module {
        invariant module x > 0;
    }

    // PAIR: SpecInvariant -> SpecInvariantInternal0Pack
    // PAIR: SpecInvariantInternal0Pack -> PackTok
    spec module {
        invariant pack x > 0;
    }

    // PAIR: SpecInvariant -> SpecInvariantInternal0Unpack
    // PAIR: SpecInvariantInternal0Unpack -> UnpackTok
    spec module {
        invariant unpack x > 0;
    }

    // PAIR: SpecInvariant -> SpecInvariantInternal0Update
    // PAIR: SpecInvariantInternal0Update -> UpdateTok
    spec module {
        invariant update x > 0;
    }

    // === SpecLet missing pairs ===

    // PAIR: SpecLet -> HiddenExpressionCastExpression
    spec module {
        let x = 1 as u64;
    }

    // PAIR: SpecLet -> HiddenExpressionIdentifiedExpression
    spec module {
        let x = 'label: 1 + 2;
    }

    // PAIR: SpecLet -> HiddenExpressionIfExpression
    spec module {
        let x = if (true) 1 else 2;
    }

    // PAIR: SpecLet -> HiddenExpressionMacroCallExpression
    spec module {
        let x = assert!(true);
    }

    // === SpecProperty missing pairs ===

    // PAIR: SpecProperty -> HiddenLiteralValueAddressLiteral
    spec module {
        pragma verify = @0x1;
    }

    // PAIR: SpecProperty -> HiddenLiteralValueByteStringLiteral
    spec module {
        pragma name = b"hello";
    }

    // PAIR: SpecProperty -> HiddenLiteralValueHexStringLiteral
    spec module {
        pragma name = x"0A";
    }

    // PAIR: SpecProperty -> HiddenLiteralValueNumLiteral
    spec module {
        pragma timeout = 100;
    }

    // PAIR: SpecProperty -> HiddenLiteralValueStringLiteral
    spec module {
        pragma name = "hello";
    }

    // === SpecVariable pairs ===

    // PAIR: SpecVariable -> HiddenTypeFunctionType
    spec module {
        global callback: |u64| -> bool;
    }

    // PAIR: SpecVariable -> HiddenTypeRefType
    spec module {
        global ptr: &u64;
    }

    // PAIR: SpecVariable -> HiddenTypeTupleType
    spec module {
        global pair: (u64, bool);
    }

    // PAIR: SpecVariable -> SpecVariableInternal0Global
    // PAIR: SpecVariableInternal0Global -> GlobalTok
    spec module {
        global counter: u64;
    }

    // PAIR: SpecVariable -> SpecVariableInternal0Local
    // PAIR: SpecVariableInternal0Local -> LocalTok
    spec module {
        local temp: u64;
    }

    // PAIR: SpecVariable -> TypeParameters
    spec module {
        global my_var<T>: u64;
    }
}
