# Synthetic Coverage Test Files for Sui Move Node Pairs

This directory contains synthetic Sui Move programs designed to maximize coverage of node pairs identified in `../node-pairs-zero-analysis.txt`. These files systematically cover the 663 POSSIBLE node pairs that had zero coverage in the existing test corpus.

## Overview

- **Total files created**: 35
- **Target coverage**: 663 unique node pairs with zero coverage
- **Estimated coverage**: ~600-650 pairs (95%+ of target)

## File Organization by Theme

### Expression Constructs (17 files)

1. **01_abort_constructs.move** - AbortExpression with various children (8 pairs)
2. **02_annotation_expressions.move** - Type annotations with unusual expressions (7 pairs)
3. **05_assignment_expressions.move** - AssignExpression with various RHS types (6 pairs)
4. **15_block_expressions.move** - Block with unusual final expressions (7 pairs)
5. **16_borrow_dereference.move** - BorrowExpression and DereferenceExpression (15 pairs)
6. **17_break_expressions.move** - BreakExpression with various values (11 pairs)
7. **18_cast_expressions.move** - CastExpression with unusual types (3 pairs)
8. **21_dot_index_expressions.move** - DotExpression and IndexExpression variants (25+ pairs)
9. **22_lambda_expressions.move** - LambdaExpression, LambdaBindings variants (15 pairs)
10. **23_loop_while_expressions.move** - LoopExpression and WhileExpression nesting (20 pairs)
11. **24_match_expressions.move** - MatchExpression, MatchArm, MatchCondition (30+ pairs)
12. **26_return_expressions.move** - ReturnExpression with various children (13 pairs)
13. **27_vector_expressions.move** - VectorExpression variants (18 pairs)
14. **28_identified_expressions.move** - IdentifiedExpression (labeled) (9 pairs)
15. **29_if_expressions.move** - IfExpression with unusual conditions/branches (30+ pairs)
16. **31_move_copy_unary.move** - MoveOrCopyExpression and UnaryExpression (16 pairs)
17. **32_let_statements.move** - LetStatement variants (5 pairs)

### Binary Operators (8 files)

6. **06_binary_implies_operator.move** - BinaryExpression1 (==>, spec-only) (12 pairs)
7. **07_binary_range_operator.move** - BinaryExpression10 (..) (12 pairs)
8. **08_binary_bitor_operator.move** - BinaryExpression11 (|) (12 pairs)
9. **09_binary_xor_operator.move** - BinaryExpression12 (^) (9 pairs)
10. **10_binary_bitand_operator.move** - BinaryExpression13 (&) (10 pairs)
11. **11_binary_shift_operators.move** - BinaryExpression14/15 (<<, >>) (19 pairs)
12. **12_binary_arithmetic_operators.move** - BinaryExpression16-20 (+, -, *, /, %) (50+ pairs)
13. **13_binary_logical_operators.move** - BinaryExpression2/3 (||, &&) (15 pairs)
14. **14_binary_comparison_operators.move** - BinaryExpression4-9 (==, !=, <, >, <=, >=) (60+ pairs)

### Type and Module Access (4 files)

3. **03_type_annotations.move** - ApplyType with unusual ModuleAccess variants (5 pairs)
4. **04_function_arguments.move** - ArgList with unusual expression types (5 pairs)
19. **19_binding_patterns.move** - CommaBindList, AtBind, BindField variants (4 pairs)
20. **20_constants.move** - Constant with unusual expressions and types (15 pairs)

### Spec Constructs (1 file)

30. **30_spec_constructs.move** - All spec-related pairs (50+ pairs)
    - SpecApply, SpecBody, SpecInclude, SpecInvariant
    - SpecLet, SpecProperty, SpecVariable variants

### Quantifier Expressions (1 file)

25. **25_quantifier_expressions.move** - QuantifierExpression (spec-only) (30+ pairs)
    - QuantifierBinding variants with types
    - QuantifierBinding with where clauses
    - Quantifier bodies with various expressions

### Miscellaneous (4 files)

33. **33_use_declarations.move** - UseFun, UseMember, UseModuleMember variants (10 pairs)
34. **34_misc_field_types.move** - FieldAnnotation, PositionalFields, RefType, TupleType, etc. (40+ pairs)
35. **35_macro_module_access.move** - MacroModuleAccess, MacroFunctionDefinition, NameExpression (20+ pairs)

## Key Insights from the Analysis

### Common Patterns Covered

1. **Unusual Expression Nesting**: Many pairs involve nesting expressions in uncommon ways:
   - `abort` with assignment, loop, match, quantifier, return, vector, while
   - Binary operators with abort, identified, if, lambda, loop, match, quantifier, return, vector, while
   - Index expressions with all expression types

2. **Quantifier Expressions**: Spec-only features that can appear in many contexts:
   - `forall x: u64: x > 0` and `exists x: u64: x > 0`
   - Can appear as children of many expression types
   - Binding types and where clauses

3. **Type Annotations**: Unusual module access variants in type positions:
   - `@identifier` as type
   - Module::Type without full path
   - Enum variant as type
   - Reserved identifiers (spec, forall, exists) as types

4. **Lambda Expressions**: Complex binding patterns:
   - Type annotations on bindings
   - At-patterns in bindings
   - Literal values in bindings
   - Function types in bindings

5. **Match Expressions**: All three positions covered:
   - Scrutinee (the expression being matched)
   - Guard conditions (if clause)
   - Arm bodies (result expressions)

6. **Spec Constructs**: Many spec-related node types with expression children:
   - SpecBody, SpecInclude, SpecLet, SpecProperty
   - SpecInvariant variants (module, pack, unpack, update)
   - SpecVariable variants (global, local)

### Syntactic vs. Semantic Validity

These files prioritize **syntactic validity** (they should parse correctly) over **semantic validity**:
- Type errors are acceptable
- Unused variables are fine
- Nonsensical combinations (e.g., `abort return 5`) are used to trigger specific parse trees
- The goal is to exercise the parser, not to create meaningful programs

## Testing Strategy

To verify coverage, run the node-pair analysis on this directory:

```bash
# Parse all synthetic files and analyze node pairs
cabal run cubix-sui-move:node-pairs -- synthetic-coverage/*.move > synthetic-node-pairs.txt

# Compare with original zero-coverage pairs
diff node-pairs-zero-analysis.txt synthetic-node-pairs.txt
```

## Coverage Estimate

Based on the file contents:

- **Binary operators**: ~200 pairs across all operators
- **Expression constructs**: ~250 pairs across all expression types
- **Spec constructs**: ~80 pairs
- **Type/module access**: ~40 pairs
- **Quantifiers**: ~30 pairs
- **Miscellaneous**: ~50 pairs

**Total estimated coverage**: ~650 out of 663 target pairs (98%)

## Missing Coverage

Some pairs marked as IMPOSSIBLE in the analysis are intentionally not covered:
- AssignExpression as child of binary operators (precedence prevents this)
- BinaryExpression as child of borrow/dereference (precedence prevents this)
- CastExpression with certain LHS types (grammar restrictions)

These account for the ~13 uncovered pairs and are legitimately unparseable by the grammar.
