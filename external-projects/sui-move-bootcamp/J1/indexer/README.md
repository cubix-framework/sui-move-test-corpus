# Sui Hero Index

A demo using `sui-indexer-alt-framework` to index all active addresses since
genesis from the chain. To set things up, run:

```sh
$ diesel setup \
    --database-url="postgres://postgres:postgrespw@localhost:5432/sui_hero" \
    --migration-dir migrations
$ diesel migration generate create_tables
$ diesel migration run \
    --database-url="postgres://postgres:postgrespw@localhost:5432/sui_hero" \
    --migration-dir migrations
```

To run the indexer:

```sh
$ RUST_LOG=info cargo run --release -- \
    --remote-store-url https://checkpoints.testnet.sui.io \
    --first-checkpoint 183081694
```

(The indexer defaults to populating the database set-up in the previous code
snippet, but this can be overridden using the `--database-url` flag).