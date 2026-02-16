# Sui Move Test Corpus

A collection of Sui Move programs for testing the Cubix framework's Sui Move language support.

## Statistics

**Total**: ~787,000 lines of Move code across ~8,900 files

## License Information

All Move code in this corpus comes with clear, permissive open-source licenses:

### Core Corpus (from tree-sitter-move / MystenLabs/sui)

| Directory | Lines | License | Source |
|-----------|-------|---------|--------|
| `crates/` | 114,326 | Apache 2.0 | MystenLabs/sui |
| `external-crates/` | 83,521 | Apache 2.0 | MystenLabs/sui |
| `examples/` | 11,949 | Apache 2.0 | MystenLabs/sui |
| `bridge/` | 145 | Apache 2.0 | MystenLabs/sui |
| `dapps/` | 205 | Apache 2.0 | MystenLabs/sui |

### External Projects

| Project | Files | Lines | License | License File |
|---------|-------|-------|---------|--------------|
| **sui-smart-contracts** (kunalabs) | 401 | 97,968 | Apache 2.0 | Yes |
| **sui-move-analyzer** (movebit) | 2,520 | 68,609 | Apache 2.0 | Yes (external-crates) |
| **pyth-crosschain** | 241 | 63,584 | Apache 2.0 | Yes |
| **deepbookv3** (MystenLabs) | 67 | 54,796 | Apache 2.0 | Yes |
| **nft-protocol** (Origin-Byte) | 160 | 43,837 | Viral Public License | Yes |
| **sui-lending-protocol** (Scallop) | 171 | 28,317 | Apache 2.0 | Yes |
| **wormhole** | 109 | 26,278 | Apache 2.0 | Yes |
| **suilend** | 32 | 17,963 | Apache 2.0 | Via parent org |
| **suins-contracts** (MystenLabs) | 90 | 17,218 | Apache 2.0 | Yes |
| **movemate** (pentagon) | 42 | 15,921 | MIT | Via README |
| **walrus-docs** (MystenLabs) | 62 | 14,604 | Apache 2.0 | Yes |
| **contracts-sui** (OpenZeppelin) | 35 | 12,840 | MIT | Yes |
| **flowx-clmm** | 26 | 12,316 | MIT | Via README badge |
| **sui-prover** (asymptotic) | 402 | 12,283 | Apache 2.0 | Via org |
| **sui-cctp** (Circle) | 31 | 10,560 | Apache 2.0 | Yes |
| **originmate** (Origin-Byte) | 21 | 8,925 | MIT | Yes |
| **mystenlab-apps** | 46 | 8,021 | Apache 2.0 | Yes |
| **suiswap-contract** | 8 | 7,634 | Apache 2.0 | Yes |
| **move-oracles** (pentagon) | 58 | 7,542 | MIT | Via README |
| **cetus-clmm-interface** | 38 | 7,457 | Apache 2.0 | Via org |
| **sc-dex** (Interest Protocol) | 27 | 4,903 | Apache 2.0 | Via org |
| **switchboard-sui** | 29 | 4,821 | Apache 2.0 | Yes |
| **sui-move-bootcamp** (MystenLabs) | 68 | 4,595 | Apache 2.0 | Via parent org |
| **turbos-sui-move-interface** | 24 | 4,251 | Apache 2.0 | Via org |
| **integer-mate** (Cetus) | 16 | 4,185 | MIT | Yes |
| **sui-defi** (Interest Protocol) | 26 | 3,847 | Apache 2.0 | Via org |
| **move-stl** (Cetus) | 12 | 2,740 | MIT | Yes |
| **sui-client-gen** (kunalabs) | 26 | 2,538 | Apache 2.0 | Yes |
| **sui-playground** | 31 | 2,075 | Apache 2.0 | Via content |
| **blackjack-sui** (MystenLabs) | 2 | 1,799 | Apache 2.0 | Via parent org |
| **sui-move-intro-course** | 21 | 1,461 | CC BY-SA 4.0 | Yes |
| **multisig_tic-tac-toe** (MystenLabs) | 2 | 776 | Apache 2.0 | Via parent org |
| **walrus-sites** (MystenLabs) | 4 | 634 | Apache 2.0 | Yes |
| **sui-nft-marketplace-sample** | 2 | 358 | Apache 2.0 | Via content |
| **simple_nft_marketplace** | 1 | 340 | Apache 2.0 | Yes |
| **kriya-dex-interface** | 3 | 338 | Apache 2.0 | Via org |
| **move-prover-examples** (Zellic) | 8 | 294 | Apache 2.0 | Via org |
| **encrypted-nft-poc** (MystenLabs) | 1 | 229 | Apache 2.0 | Yes |
| **pysui** | 1 | 113 | Apache 2.0 | Yes |

### License Summary

| License | Projects | Lines of Move Code |
|---------|----------|-------------------|
| **Apache 2.0** | ~35 | ~700,000 |
| **MIT** | 7 | ~55,000 |
| **Viral Public License** | 1 | ~44,000 |
| **CC BY-SA 4.0** | 1 | ~1,500 |

### License Notes

- **Apache 2.0**: Permissive license allowing commercial use, modification, distribution
- **MIT**: Permissive license similar to Apache 2.0
- **Viral Public License (VPL)**: Permissive copyleft - derivative works must use VPL
- **CC BY-SA 4.0**: Educational content license requiring attribution and share-alike

**Removed**: The proprietary `bluefin_spot` code has been removed from this corpus as it had a non-permissive license.

## Usage

This corpus is used for:
- Testing the Cubix Sui Move parser
- Analyzing node pair coverage in the grammar
- Validating round-trip (parse -> pretty-print -> parse) correctness

## Structure

- `bridge/`, `crates/`, `examples/`, `dapps/`, `external-crates/` - Core Sui Move code (Apache 2.0)
- `external-projects/` - Third-party open-source Sui Move projects (various licenses as listed above)

## Coverage

See `node-pairs-coverage.txt` for the grammar coverage report.
