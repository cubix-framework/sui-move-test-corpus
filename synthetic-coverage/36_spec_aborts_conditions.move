// Synthetic test file for spec aborts_if, aborts_with/modifies, and spec condition pairs
// Covers: HiddenSpecAbortIf, HiddenSpecAbortWithOrModifies, HiddenSpecCondition, and related pairs

module synthetic::spec_aborts_conditions {

    fun foo(_x: u64): u64 { 0 }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionAbortExpression
    spec foo {
        aborts_if abort 0;
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionAssignExpression
    spec foo {
        aborts_if x = true;
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionCastExpression
    spec foo {
        aborts_if x as bool;
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionIdentifiedExpression
    spec foo {
        aborts_if 'lbl: x;
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionIfExpression
    spec foo {
        aborts_if if (true) false else true;
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionLambdaExpression
    spec foo {
        aborts_if |x| x > 0;
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionLoopExpression
    spec foo {
        aborts_if loop { break true };
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionMacroCallExpression
    spec foo {
        aborts_if assert!(true);
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionMatchExpression
    spec foo {
        aborts_if match (x) { _ => true };
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionReturnExpression
    spec foo {
        aborts_if return true;
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionVectorExpression
    spec foo {
        aborts_if vector[true];
    }

    // PAIR: HiddenSpecAbortIf -> HiddenExpressionWhileExpression
    spec foo {
        aborts_if while (true) { break false };
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionAbortExpression
    spec foo {
        aborts_with abort 0;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionAssignExpression
    spec foo {
        aborts_with x = 1;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionBinaryExpression
    spec foo {
        aborts_with x + y;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionCastExpression
    spec foo {
        aborts_with x as u64;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionIdentifiedExpression
    spec foo {
        aborts_with 'lbl: x;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionIfExpression
    spec foo {
        aborts_with if (true) 1 else 2;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionLambdaExpression
    spec foo {
        aborts_with |x| x;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionLoopExpression
    spec foo {
        aborts_with loop { break 1 };
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionMacroCallExpression
    spec foo {
        aborts_with assert!(true);
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionMatchExpression
    spec foo {
        aborts_with match (x) { _ => 0 };
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionQuantifierExpression
    spec foo {
        aborts_with forall x: u64: x > 0;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionReturnExpression
    spec foo {
        aborts_with return 0;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionUnaryExpression
    spec foo {
        aborts_with !false;
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionVectorExpression
    spec foo {
        aborts_with vector[1, 2];
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenExpressionWhileExpression
    spec foo {
        aborts_with while (true) { break 0 };
    }

    // PAIR: HiddenSpecAbortWithOrModifies -> HiddenSpecAbortWithOrModifiesInternal0AbortsWith
    // PAIR: HiddenSpecAbortWithOrModifiesInternal0AbortsWith -> AbortsWithTok
    spec foo {
        aborts_with 0;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionAbortExpression
    spec foo {
        ensures abort 1;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionAssignExpression
    spec foo {
        ensures x = 1;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionCastExpression
    spec foo {
        ensures result as u128;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionIdentifiedExpression
    spec foo {
        ensures 'a: result + 1;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionIfExpression
    spec foo {
        ensures if (x > 0) true else false;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionLambdaExpression
    spec foo {
        ensures |v| v > 0;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionLoopExpression
    spec foo {
        ensures loop { break true };
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionMacroCallExpression
    spec foo {
        ensures assert!(true);
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionMatchExpression
    spec foo {
        ensures match (result) { 0 => true, _ => false };
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionReturnExpression
    spec foo {
        ensures return true;
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionVectorExpression
    spec foo {
        ensures vector[true];
    }

    // PAIR: HiddenSpecCondition -> HiddenExpressionWhileExpression
    spec foo {
        ensures while (true) { break true };
    }

    // PAIR: HiddenSpecConditionInternal02 -> ModuleTok
    spec foo {
        requires module true;
    }

    // PAIR: HiddenSpecConditionInternal0Kind -> HiddenSpecConditionKindDecreases
    // PAIR: HiddenSpecConditionKindDecreases -> DecreasesTok
    spec foo {
        decreases x;
    }

    // PAIR: HiddenSpecConditionInternal0Kind -> HiddenSpecConditionKindSucceedsIf
    // PAIR: HiddenSpecConditionKindSucceedsIf -> SucceedsIfTok
    spec foo {
        succeeds_if x > 0;
    }
}
