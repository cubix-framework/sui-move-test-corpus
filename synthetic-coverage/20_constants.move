// Synthetic test file for Constant node pairs
// Covers: Constant -> various expression and type children

module synthetic::constants {

    // PAIR: Constant -> HiddenExpressionAbortExpression
    const CONST_ABORT: u64 = abort 0;

    // PAIR: Constant -> HiddenExpressionAssignExpression
    const CONST_ASSIGN: u64 = x = 5;

    // PAIR: Constant -> HiddenExpressionCallExpression
    const CONST_CALL: u64 = f();

    // PAIR: Constant -> HiddenExpressionIdentifiedExpression
    const CONST_IDENTIFIED: u64 = 'lab: 5;

    // PAIR: Constant -> HiddenExpressionLambdaExpression
    const CONST_LAMBDA: |u64| -> u64 = |x| x + 1;

    // PAIR: Constant -> HiddenExpressionLoopExpression
    const CONST_LOOP: u64 = loop { break 1 };

    // PAIR: Constant -> HiddenExpressionMacroCallExpression
    const CONST_MACRO: u64 = foo!(x);

    // PAIR: Constant -> HiddenExpressionMatchExpression
    const CONST_MATCH: u64 = match (x) { _ => 0 };

    // PAIR: Constant -> HiddenExpressionQuantifierExpression
    spec const CONST_QUANTIFIER: bool = forall x: u64: x > 0;

    // PAIR: Constant -> HiddenExpressionReturnExpression
    const CONST_RETURN: u64 = return 5;

    // PAIR: Constant -> HiddenExpressionVectorExpression
    const CONST_VECTOR: vector<u64> = vector[1, 2, 3];

    // PAIR: Constant -> HiddenExpressionWhileExpression
    const CONST_WHILE: u64 = while (true) { break };

    // PAIR: Constant -> HiddenTypeFunctionType
    const CONST_FN_TYPE: |u64| -> u64 = |x| x;

    // PAIR: Constant -> HiddenTypeRefType
    const CONST_REF_TYPE: &u64 = &0;

    // PAIR: Constant -> HiddenTypeTupleType
    const CONST_TUPLE_TYPE: (u64, bool) = (1, true);
}
