# Sui Move Test Corpus

A collection of Sui Move programs for testing the Cubix framework's Sui Move language support.

## Source

The initial corpus was collected from the [tree-sitter-move](https://github.com/MystenLabs/tree-sitter-move) repository, which contains Sui Move test files and examples.

## Usage

This corpus is used for:
- Testing the Cubix Sui Move parser
- Analyzing node pair coverage in the grammar
- Validating round-trip (parse -> pretty-print -> parse) correctness

## Structure

- `bridge/` - Bridge-related Move contracts
- `crates/` - Test files from various Sui crates
- `examples/` - Example Move programs
- `dapps/` - Decentralized application examples
- Other directories from the Sui repository
