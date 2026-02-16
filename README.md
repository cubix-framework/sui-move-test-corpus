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

## Coverage

As of the latest analysis, this corpus contains **5130 Sui Move files** which exercise **437 unique node pair types** in the grammar.

### External Projects Included

- **interest-protocol/sui-defi** - DeFi contracts
- **kunalabs-io/sui-smart-contracts** - AMM, access management
- **abhi3700/sui-playground** - Learning examples
- **Zellic/move-prover-examples** - Formal verification specs
- **asymptotic-code/sui-prover** - Sui prover
- **Origin-Byte/nft-protocol** - NFT standard
- **pawankumargali/sui-nft-marketplace-sample** - NFT marketplace
- **suiph/simple_nft_marketplace** - Simple NFT marketplace

See `node-pairs-coverage.txt` for the full coverage report.
