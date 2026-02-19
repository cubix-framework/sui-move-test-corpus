// Synthetic test file for Spec-related node pairs
// Covers: SpecApply, SpecBody, SpecInclude, SpecInvariant, SpecLet, SpecProperty, SpecVariable, etc.

module synthetic::spec_constructs {

    // PAIR: SpecBody -> HiddenExpressionAbortExpression
    spec module {
        ensures abort 1;
    }

    // PAIR: SpecBody -> HiddenExpressionAssignExpression
    spec module {
        let x;
        ensures x = 5;
    }

    // PAIR: SpecBody -> HiddenExpressionLambdaExpression
    spec module {
        ensures |x| x;
    }

    // PAIR: SpecBody -> HiddenExpressionLoopExpression
    spec module {
        ensures loop { break true };
    }

    // PAIR: SpecBody -> HiddenExpressionMatchExpression
    spec module {
        ensures match (x) { _ => true };
    }

    // PAIR: SpecBody -> HiddenExpressionQuantifierExpression
    spec module {
        ensures forall x: u64: x > 0;
    }

    // PAIR: SpecBody -> HiddenExpressionReturnExpression
    spec module {
        ensures return true;
    }

    // PAIR: SpecBody -> HiddenExpressionVectorExpression
    spec module {
        ensures vector[true];
    }

    // PAIR: SpecBody -> HiddenExpressionWhileExpression
    spec module {
        ensures while (true) { break true };
    }

    // PAIR: SpecInclude -> HiddenExpressionAbortExpression
    spec module {
        include abort 1;
    }

    // PAIR: SpecInclude -> HiddenExpressionAssignExpression
    spec module {
        let x;
        include x = 5;
    }

    // PAIR: SpecInclude -> HiddenExpressionLambdaExpression
    spec module {
        include |x| x;
    }

    // PAIR: SpecInclude -> HiddenExpressionLoopExpression
    spec module {
        include loop { break MySchema };
    }

    // PAIR: SpecInclude -> HiddenExpressionMatchExpression
    spec module {
        include match (x) { _ => MySchema };
    }

    // PAIR: SpecInclude -> HiddenExpressionQuantifierExpression
    spec module {
        include forall x: u64: x > 0;
    }

    // PAIR: SpecInclude -> HiddenExpressionReturnExpression
    spec module {
        include return MySchema;
    }

    // PAIR: SpecInclude -> HiddenExpressionVectorExpression
    spec module {
        include vector[MySchema];
    }

    // PAIR: SpecInclude -> HiddenExpressionWhileExpression
    spec module {
        include while (true) { break MySchema };
    }

    // PAIR: SpecLet -> HiddenExpressionAbortExpression
    spec module {
        let x = abort 1;
    }

    // PAIR: SpecLet -> HiddenExpressionAssignExpression
    spec module {
        let y;
        let x = y = 5;
    }

    // PAIR: SpecLet -> HiddenExpressionLambdaExpression
    spec module {
        let f = |x| x;
    }

    // PAIR: SpecLet -> HiddenExpressionLoopExpression
    spec module {
        let x = loop { break 1 };
    }

    // PAIR: SpecLet -> HiddenExpressionMatchExpression
    spec module {
        let x = match (y) { _ => 1 };
    }

    // PAIR: SpecLet -> HiddenExpressionQuantifierExpression
    spec module {
        let b = forall x: u64: x > 0;
    }

    // PAIR: SpecLet -> HiddenExpressionReturnExpression
    spec module {
        let x = return 5;
    }

    // PAIR: SpecLet -> HiddenExpressionVectorExpression
    spec module {
        let v = vector[1, 2];
    }

    // PAIR: SpecLet -> HiddenExpressionWhileExpression
    spec module {
        let x = while (true) { break 1 };
    }

    // PAIR: SpecProperty -> HiddenExpressionAbortExpression
    spec module {
        property abort 1;
    }

    // PAIR: SpecProperty -> HiddenExpressionAssignExpression
    spec module {
        let x;
        property x = true;
    }

    // PAIR: SpecProperty -> HiddenExpressionLambdaExpression
    spec module {
        property |x| x;
    }

    // PAIR: SpecProperty -> HiddenExpressionLoopExpression
    spec module {
        property loop { break true };
    }

    // PAIR: SpecProperty -> HiddenExpressionMatchExpression
    spec module {
        property match (x) { _ => true };
    }

    // PAIR: SpecProperty -> HiddenExpressionQuantifierExpression
    spec module {
        property forall x: u64: x > 0;
    }

    // PAIR: SpecProperty -> HiddenExpressionReturnExpression
    spec module {
        property return true;
    }

    // PAIR: SpecProperty -> HiddenExpressionVectorExpression
    spec module {
        property vector[true];
    }

    // PAIR: SpecProperty -> HiddenExpressionWhileExpression
    spec module {
        property while (true) { break true };
    }

    // PAIR: SpecApply -> HiddenExpressionAbortExpression
    spec schema MySchema {
        apply MyFun to abort 1;
    }

    // PAIR: SpecApplyPattern -> HiddenExpressionAbortExpression
    spec module {
        apply MySchema to abort 1;
    }

    // PAIR: SpecApplyPatternInternal0Public -> HiddenExpressionAbortExpression
    spec module {
        apply MySchema to public abort 1;
    }

    // PAIR: SpecInvariantInternal0Module -> HiddenExpressionAbortExpression
    spec module {
        invariant module abort 1;
    }

    // PAIR: SpecInvariantInternal0Pack -> HiddenExpressionAbortExpression
    spec module {
        invariant pack abort 1;
    }

    // PAIR: SpecInvariantInternal0Unpack -> HiddenExpressionAbortExpression
    spec module {
        invariant unpack abort 1;
    }

    // PAIR: SpecInvariantInternal0Update -> HiddenExpressionAbortExpression
    spec module {
        invariant update abort 1;
    }

    // PAIR: SpecVariableInternal0Global -> HiddenExpressionAbortExpression
    spec module {
        global x: u64 = abort 1;
    }

    // PAIR: SpecVariableInternal0Local -> HiddenExpressionAbortExpression
    spec module {
        local x: u64 = abort 1;
    }
}
