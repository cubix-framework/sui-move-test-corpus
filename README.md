# Sui Move Test Corpus

A collection of Sui Move programs for testing the Cubix framework's Sui Move language support.

**All code in this corpus is Sui Move** (or syntactically compatible Sui Move forks like IOTA and MangoNet). Aptos Move, Starcoin, Diem, and other non-Sui Move dialects have been excluded because they use incompatible syntax (e.g., `script` blocks, which are not part of the Sui Move grammar).

## Statistics

**Total**: ~1,480,000 unique lines of Sui Move code across ~10,832 files (duplicates removed via MD5 hashing)

## License Information

All code in this corpus comes with clear, permissive open-source licenses:

### Core Corpus (from MystenLabs/sui)

| Directory | Files | Lines | License | Source |
|-----------|-------|-------|---------|--------|
| `crates/` | 708 | 87,586 | Apache 2.0 | MystenLabs/sui |
| `external-crates/` | 799 | 28,994 | Apache 2.0 | MystenLabs/sui |
| `examples/` | 73 | 10,242 | Apache 2.0 | MystenLabs/sui |

### Sui-Compatible Forks

| Project | Files | Lines | License | Notes |
|---------|-------|-------|---------|-------|
| **bityoume** | 2,642 | 168,624 | Apache 2.0 | Sui fork |
| **iota-full-extra** (IOTA Foundation) | 1,519 | 149,372 | Apache 2.0 | Sui fork (uses `iota::` namespace) |
| **mango** (MangoNet Labs) | 928 | 79,551 | Apache 2.0 | Sui fork (uses `mgo::` namespace) |
| **punch-sui** | 326 | 68,344 | Apache 2.0 | Sui fork |

### External Sui Move Projects

| Project | Files | Lines | License |
|---------|-------|-------|---------|
| **sui-smart-contracts** (kunalabs) | 332 | 81,396 | Apache 2.0 |
| **deepbookv3** (MystenLabs) | 66 | 54,781 | Apache 2.0 |
| **nft-protocol** (Origin-Byte) | 160 | 43,837 | Viral Public License |
| **pyth-crosschain** (Sui contracts) | 151 | 41,354 | Apache 2.0 |
| **navi-smart-contracts** | 74 | 31,888 | GPL v3 |
| **walrus** (MystenLabs) | 98 | 27,315 | Apache 2.0 |
| **sui-lending-protocol** (Scallop) | 137 | 22,757 | Apache 2.0 |
| **kunalabs-full** | 34 | 21,635 | Apache 2.0 |
| **dola-protocol** (OmniBTC, Sui contracts) | 72 | 19,378 | GPL v3 |
| **capsules** (Sui-Potatoes) | 99 | 18,320 | MIT |
| **suins-contracts** (MystenLabs) | 90 | 17,218 | Apache 2.0 |
| **suitears** | 57 | 16,627 | Apache 2.0 |
| **sui-potatoes** | 89 | 16,664 | MIT |
| **walrus-docs** (MystenLabs) | 62 | 14,604 | Apache 2.0 |
| **axelar-sui** (Axelar) | 58 | 12,979 | MIT |
| **contracts-sui** (OpenZeppelin) | 35 | 12,840 | MIT |
| **flowx-clmm** | 26 | 12,316 | MIT |
| **sui-cctp** (Circle) | 31 | 10,560 | Apache 2.0 |
| **OmniSwap** (Sui contracts) | 31 | 9,875 | GPL v3 |
| **mysten-apps** | 46 | 8,021 | Apache 2.0 |
| **suiswap-contract** | 8 | 7,634 | Apache 2.0 |
| **move-oracles** (pentagon) | 58 | 7,542 | MIT |
| **originmate** (Origin-Byte) | 11 | 7,480 | MIT |
| **cetus-clmm-interface** | 38 | 7,457 | Apache 2.0 |
| **typus-dov** | 20 | 7,380 | Apache 2.0 |
| **dubhe** | 77 | 6,393 | Apache 2.0 |
| **movefuns** (Sui contracts) | 31 | 6,078 | Apache 2.0 |
| **movescriptions** | 32 | 5,676 | Apache 2.0 |
| **sc-dex** (Interest Protocol) | 27 | 4,903 | Apache 2.0 |
| **switchboard-sui** | 29 | 4,821 | Apache 2.0 |
| **sui-move-bootcamp** (MystenLabs) | 65 | 4,498 | Apache 2.0 |
| **turbos-sui-move-interface** | 24 | 4,251 | Apache 2.0 |
| **pokemon** | 26 | 4,160 | MIT |
| **suidouble_metadata** | 14 | 4,111 | Apache 2.0 |
| **sui-defi** (Interest Protocol) | 26 | 3,847 | Apache 2.0 |
| **movemate** (Sui contracts) | 16 | 3,481 | MIT |
| **suidouble8192** | 6 | 3,126 | Apache 2.0 |
| **move-stl** (Cetus) | 12 | 2,740 | MIT |
| **sui-client-gen** (kunalabs) | 19 | 2,446 | Apache 2.0 |
| **sui-playground** | 30 | 2,075 | Apache 2.0 |
| **Sui-AMM-swap** | 10 | 2,072 | Apache 2.0 |
| **mvr** (MystenLabs) | 26 | 2,016 | Apache 2.0 |
| **move-sui-extra** | 28 | 1,839 | Apache 2.0 |
| **blackjack-sui** (MystenLabs) | 2 | 1,799 | Apache 2.0 |
| **sui-move-intro-course** | 21 | 1,461 | CC BY-SA 4.0 |
| **sui-move-analyzer** | 20 | 1,359 | Apache 2.0 |
| **move-projects** | 12 | 883 | Apache 2.0 |
| **multisig_tic-tac-toe** (MystenLabs) | 2 | 776 | Apache 2.0 |
| **layerswap-atomic-bridge** | 4 | 640 | Apache 2.0 |
| **walrus-sites** (MystenLabs) | 4 | 634 | Apache 2.0 |
| **sui-redpacket** | 2 | 547 | Apache 2.0 |
| **suia** | 3 | 544 | Apache 2.0 |
| **omnibridge** (Sui contracts) | 3 | 458 | Apache 2.0 |
| **suidouble** | 2 | 457 | Apache 2.0 |
| **bucket-periphery** | 4 | 383 | MIT |
| **sui-nft-marketplace-sample** | 2 | 358 | Apache 2.0 |
| **simple_nft_marketplace** | 1 | 340 | Apache 2.0 |
| **kriya-dex-interface** | 3 | 338 | Apache 2.0 |
| **move-prover-examples** (Zellic) | 8 | 294 | Apache 2.0 |
| **encrypted-nft-poc** (MystenLabs) | 1 | 229 | Apache 2.0 |
| **suidouble-bot-score** | 1 | 158 | Apache 2.0 |
| **suidouble-sample-color** | 1 | 150 | Apache 2.0 |
| **pysui** | 1 | 113 | Apache 2.0 |
| **typus** (Typus Labs) | 124 | 61,493 | Apache 2.0 |
| **okx-dex-router** (OKX Labs) | 232 | 18,363 | MIT |
| **bucket-oracle** (Bucket Protocol) | 122 | 18,341 | MIT |
| **account-framework** (Account.tech) | 57 | 17,336 | Apache 2.0 |
| **bucket-v1-core** (Bucket Protocol) | 58 | 14,888 | MIT |
| **sui-native** (GoNative) | 62 | 12,692 | MPL 2.0 |
| **account-registry** (Account.tech) | 31 | 9,635 | Apache 2.0 |
| **dubhe-framework** (0xobelisk) | 55 | 4,785 | Apache 2.0 |
| **liquid-staking** (Suilend) | 13 | 4,394 | MIT |
| **typus-interface** (Typus Labs) | 79 | 4,245 | MIT |
| **move-book** (MystenLabs) | 78 | 3,394 | Apache 2.0 |
| **onenet-bushi** (MystenLabs) | 9 | 3,296 | Apache 2.0 |
| **sui-nft-market-xander** | 22 | 2,740 | Apache 2.0 |
| **buckyou-contracts** (Bucket Protocol) | 20 | 2,704 | MIT |
| **satoshi-coin-flip** (MystenLabs) | 7 | 2,467 | Apache 2.0 |
| **world3-ai** (WORLD3) | 4 | 2,317 | Apache 2.0 |
| **prime-machin-contracts** (Studio Mirai) | 10 | 2,300 | MIT |
| **asset-tokenization** (MystenLabs) | 6 | 1,749 | Apache 2.0 |
| **bucket-framework** (Bucket Protocol) | 9 | 1,626 | MIT |
| **sui-mover-2024** (Bucket Protocol) | 14 | 1,376 | MIT |
| **suitears** (Interest Protocol) | 11 | 1,224 | MIT |
| **sui-meta** (suidouble) | 8 | 1,096 | Apache 2.0 |
| **typus-framework** (Typus Labs) | 5 | 940 | Apache 2.0 |
| **encode-sui-educate** (Sui Foundation) | 12 | 926 | CC BY-SA 4.0 |
| **sui-intro-zh** (RandyPen) | 15 | 919 | CC BY-SA 4.0 |
| **sui-dev-token** (Typus Labs) | 22 | 917 | Apache 2.0 |
| **pyth-crosschain-extra** (Pyth, Sui only) | 3 | 821 | Apache 2.0 |
| **controlled-treasury** (MystenLabs) | 3 | 733 | Apache 2.0 |
| **sui-nft-auction** | 3 | 725 | MIT |
| **object-market** (coming-chat) | 3 | 679 | Apache 2.0 |
| **nautilus** (MystenLabs) | 5 | 669 | Apache 2.0 |
| **sui-pumpfun** | 4 | 504 | MIT |
| **turbos-oracle** (Turbos Finance) | 5 | 503 | MIT |
| **sui-fantasy** (MystenLabs) | 2 | 420 | MIT |
| **sui-native-randomness** (MystenLabs) | 4 | 219 | Apache 2.0 |
| **multisig-move** (MystenLabs) | 2 | 198 | Apache 2.0 |
| **buck-voucher** (Bucket Protocol) | 1 | 135 | MIT |
| **navi-demo** (NAVI Protocol) | 1 | 81 | MIT |
| **encryption-public-key** (MystenLabs) | 2 | 58 | Apache 2.0 |
| **deeptrade-core** (DeeptradeProtocol) | 89 | 33,829 | MIT |
| **ramm-sui** (Aldrin Labs) | 23 | 14,265 | AGPL 3.0 |
| **aftermath-interfaces** (AftermathFinance) | 76 | 10,783 | Apache 2.0 |
| **suede** (4meta5) | 48 | 7,957 | MIT |
| **sui-extended-std** (arniebarnie) | 20 | 6,498 | MIT |
| **integer-mate** (CetusProtocol) | 16 | 4,185 | MIT |
| **goosebumps** (goosebumps-farm) | 14 | 4,075 | MIT |
| **sui-bitcoin-spv** (GoNative) | 31 | 3,521 | MPL 2.0 |
| **dmens** (coming-chat) | 3 | 1,546 | Apache 2.0 |
| **typus-coin** (Typus Labs) | 1 | 35 | MIT |

### License Summary

| License | Projects | Approximate Lines |
|---------|----------|-------------------|
| **Apache 2.0** | ~67 | ~1,110,000 |
| **MIT** | ~32 | ~270,000 |
| **Viral Public License** | 1 | ~44,000 |
| **GPL v3** | 3 | ~61,000 |
| **AGPL 3.0** | 1 | ~14,000 |
| **CC BY-SA 4.0** | 3 | ~3,300 |
| **MPL 2.0** | 2 | ~16,200 |

### Removed Projects

**Removed due to license issues**:
- `bluefin_spot` - Proprietary license
- `sui-prover` - No clear license file
- `suilend` - No clear license file
- `econia` - Business Source License

**Removed because they are not Sui Move**:
- All Aptos Move projects (use `aptos_framework`, incompatible `script` blocks)
- All Starcoin projects (use `StarcoinFramework`)
- All Diem/core Move projects (use `script` blocks not supported by Sui Move grammar)
- All Rooch projects (use `moveos_std`/`rooch_framework`, have `script` blocks)
- Solana Move, Pontem, and other non-Sui Move dialects

## Usage

This corpus is used for:
- Testing the Cubix Sui Move parser
- Analyzing node pair coverage in the grammar
- Validating round-trip (parse -> pretty-print -> parse) correctness

## Structure

- `crates/`, `examples/`, `external-crates/` - Core Sui Move code from MystenLabs/sui (Apache 2.0)
- `bityoume/`, `iota-full-extra/`, `mango/`, `punch-sui/` - Sui-compatible blockchain forks (Apache 2.0)
- `external-projects/` - Third-party open-source Sui Move projects (various licenses)
- Other top-level directories - Additional Sui Move projects

## Coverage

See `node-pairs-coverage.txt` for the full grammar coverage report.

**Summary**: 1,018 of 1,716 node pairs covered (59.3%), with 1,105,094 total node-pair occurrences across the corpus.

### Why Node-Pair Coverage?

In the 2000s, the U.S. B-2 stealth bomber program seemed doomed. Its flight software was written in JOVIAL, an old programming language, and would not run on modern hardware. To avert the loss of the B-2 fleet, Northrop Grumman tried to manually port the JOVIAL code to C and failed. They then tried to build an automated converter and also failed. In desperation, they turned to Semantic Designs.

In about 1.5 man-years, Semantic Designs built a JOVIAL-to-C converter that translated the entire 1.5 million lines of flight software perfectly on the first try. They were never allowed to see the actual source code.

How? Because they wrote unit tests for every single *pair* of grammar nodes. By the power of composition, if a translator works correctly for all pairs of nodes, it is very likely to work correctly for all programs. A node pair like (if_statement, function_call) tests that it correctly handles an if-statements whose body or condition is a function call; (binary_expression, let_expression) tests that it correctly handles a binary expression whose operand is a let expression; and so on. Covering all such pairs provides combinatorial assurance that the tool handles the interactions between language constructs, not just each construct in isolation.

This is why we use node-pair coverage as *the* metric for evaluating this test corpus. The goal is not merely to have a lot of code, but to ensure that every combination of grammar constructs that appears in real Move programs is represented, so that tools built on this corpus are tested against the full compositional structure of the language.
