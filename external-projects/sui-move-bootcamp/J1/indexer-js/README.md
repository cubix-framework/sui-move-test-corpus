```
$ npm install -g sui-events-indexer

$ sui-events-indexer generate \
-p 0x21e8decabb4a4e84a8e2a9b81237f73dee259781ef2d248bf700b08103b9e399 \
--name hero-js-indexer \
--network testnet \
-i 1000

$ cd hero-js-indexer
$ pnpm install
$ docker-compose up -d
$ pnpm run db:setup:dev
$ pnpm run indexer
```