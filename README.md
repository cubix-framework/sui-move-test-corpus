# Sui Move Test Corpus

A collection of Sui Move programs for testing the Cubix framework's Sui Move language support.

## Statistics

**Total**: ~1,280,000 lines of Move code across ~11,700 unique files (duplicates removed)

**Note on Line Count**: While we've cloned repositories totaling over 2M lines of Move code, the Move ecosystem shares substantial framework code across projects. After deduplication, the unique code is approximately 1.28M lines. Reaching 2M unique lines would require finding significantly more original Move application code that doesn't duplicate existing framework code.

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
| **suins-contracts** (MystenLabs) | 90 | 17,218 | Apache 2.0 | Yes |
| **movemate** (pentagon) | 42 | 15,921 | MIT | Yes |
| **walrus-docs** (MystenLabs) | 62 | 14,604 | Apache 2.0 | Yes |
| **contracts-sui** (OpenZeppelin) | 35 | 12,840 | MIT | Yes |
| **flowx-clmm** | 26 | 12,316 | MIT | Yes |
| **sui-cctp** (Circle) | 31 | 10,560 | Apache 2.0 | Yes |
| **originmate** (Origin-Byte) | 21 | 8,925 | MIT | Yes |
| **mystenlab-apps** | 46 | 8,021 | Apache 2.0 | Yes |
| **suiswap-contract** | 8 | 7,634 | Apache 2.0 | Yes |
| **move-oracles** (pentagon) | 58 | 7,542 | MIT | Yes |
| **cetus-clmm-interface** | 38 | 7,457 | Apache 2.0 | Yes |
| **sc-dex** (Interest Protocol) | 27 | 4,903 | Apache 2.0 | Yes |
| **switchboard-sui** | 29 | 4,821 | Apache 2.0 | Yes |
| **sui-move-bootcamp** (MystenLabs) | 68 | 4,595 | Apache 2.0 | Yes |
| **turbos-sui-move-interface** | 24 | 4,251 | Apache 2.0 | Yes |
| **integer-mate** (Cetus) | 16 | 4,185 | MIT | Yes |
| **sui-defi** (Interest Protocol) | 26 | 3,847 | Apache 2.0 | Yes |
| **move-stl** (Cetus) | 12 | 2,740 | MIT | Yes |
| **sui-client-gen** (kunalabs) | 26 | 2,538 | Apache 2.0 | Yes |
| **sui-playground** | 31 | 2,075 | Apache 2.0 | Yes |
| **blackjack-sui** (MystenLabs) | 2 | 1,799 | Apache 2.0 | Yes |
| **sui-move-intro-course** | 21 | 1,461 | CC BY-SA 4.0 | Yes |
| **multisig_tic-tac-toe** (MystenLabs) | 2 | 776 | Apache 2.0 | Yes |
| **walrus-sites** (MystenLabs) | 4 | 634 | Apache 2.0 | Yes |
| **sui-nft-marketplace-sample** | 2 | 358 | Apache 2.0 | Yes |
| **simple_nft_marketplace** | 1 | 340 | Apache 2.0 | Yes |
| **kriya-dex-interface** | 3 | 338 | Apache 2.0 | Yes |
| **move-prover-examples** (Zellic) | 8 | 294 | Apache 2.0 | Yes |
| **encrypted-nft-poc** (MystenLabs) | 1 | 229 | Apache 2.0 | Yes |
| **pysui** | 1 | 113 | Apache 2.0 | Yes |
| **sui-framework-full** (MystenLabs) | 3,200+ | 141,775 | Apache 2.0 | Yes |
| **rooch** (Rooch Network) | 1,000+ | 135,977 | Apache 2.0 | Yes |
| **move-on-aptos** | 2,000+ | 128,229 | Apache 2.0 | Yes |
| **solana-move** | 1,200+ | 82,632 | Apache 2.0 | Yes |
| **move-lang-core** | 1,200+ | 75,757 | Apache 2.0 | Yes |
| **diem** (Diem Blockchain) | 900+ | 71,393 | Apache 2.0 | Yes |
| **starcoin** | 900+ | 62,659 | Apache 2.0 | Yes |
| **walrus** (MystenLabs) | 350+ | 49,351 | Apache 2.0 | Yes |
| **movefmt** | 1,200+ | 35,729 | Apache 2.0 | Yes |
| **mvr** (MystenLabs) | 350+ | 18,600 | Apache 2.0 | Yes |
| **capsules** (Sui-Potatoes) | 120+ | 18,500 | MIT | Yes |
| **OmniSwap** | 250+ | 17,514 | GPL v3 | Yes |
| **movefuns** | 200+ | 15,785 | Apache 2.0 | Yes |
| **starcoin-framework-commons** | 100+ | 5,000 | Apache 2.0 | Yes |
| **legato-finance** | 100+ | 7,000 | MIT No Attribution | Yes |
| **starcoin-ide** | 25+ | 586 | MIT | Yes |
| **starcoin-cookbook** | 350+ | 4,850 | Apache 2.0 | Yes |
| **pokemon** | 25+ | 1,800 | MIT | Yes |
| **suidouble** | 15+ | 457 | Apache 2.0 | Yes |
| **mysten-sui-full** (MystenLabs) | 4,065 | 210,149 | Apache 2.0 | Yes |
| **move-language-repo** | 1,675 | 75,757 | Apache 2.0 | Yes |
| **mysten-sui-latest** (MystenLabs) | 3,500+ | 210,146 | Apache 2.0 | Yes |
| **move-lang-extra** | 1,200+ | 75,754 | Apache 2.0 | Yes |
| **iota** (IOTA Foundation) | 3,500+ | 207,322 | Apache 2.0 | Yes |
| **rooch-extra** (Rooch Network) | 1,000+ | 135,974 | Apache 2.0 | Yes |
| **mango** (MangoNet Labs) | 2,500+ | 110,642 | Apache 2.0 | Yes |
| **solana-move-extra** | 1,200+ | 82,629 | Apache 2.0 | Yes |
| **diem-extra** (Diem) | 900+ | 71,393 | Apache 2.0 | Yes |
| **sui-analyzer-v2** (movebit) | 2,200+ | 68,609 | Apache 2.0 | Yes |
| **starcoin-extra** (Starcoin) | 900+ | 62,659 | Apache 2.0 | Yes |
| **wormhole-extra** | 100+ | 26,278 | Apache 2.0 | Yes |
| **walrus-docs-extra** (MystenLabs) | 60+ | 14,604 | Apache 2.0 | Yes |
| **axelar-sui** (Axelar) | 80+ | 12,979 | MIT | Yes |
| **aptos-token-minter** | 60+ | 9,667 | Apache 2.0 | Yes |
| **integer-mate** (Cetus) | 16+ | 4,185 | MIT | Yes |
| **mvr-extra** (MystenLabs) | 40+ | 2,034 | Apache 2.0 | Yes |
| **sui-move-intro** | 20+ | 1,461 | CC BY-SA 4.0 | Yes |
| **taohe** | 12+ | 837 | Apache 2.0 | Yes |

### License Summary

| License | Projects | Lines of Move Code |
|---------|----------|-------------------|
| **Apache 2.0** | ~65 | ~1,100,000 |
| **MIT** | 14 | ~100,000 |
| **Viral Public License** | 1 | ~44,000 |
| **CC BY-SA 4.0** | 2 | ~3,000 |
| **GPL v3** | 1 | ~17,500 |

### License Notes

- **Apache 2.0**: Permissive license allowing commercial use, modification, distribution
- **MIT**: Permissive license similar to Apache 2.0
- **Viral Public License (VPL)**: Permissive copyleft - derivative works must use VPL
- **CC BY-SA 4.0**: Educational content license requiring attribution and share-alike

**Removed due to license issues**:
- `bluefin_spot` - Proprietary license
- `sui-prover` - No clear license file
- `suilend` - No clear license file

All remaining projects have LICENSE files in their directories or parent directories.

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
