## Sui & Move Bootcamp <> SUI TS SDK | Read Queries II

This exercise contains a simple Node project using Typescript, that gets all of the Heroes NFTs owned by a specific address on chain, iterating over the full node's pagination.

We are going to be reading the Heroes owned by the address `0x65391674eb4210940ea98ae451237d9335920297e7c8abaeb7e05b221ee36917` on testnet.

### Useful Links

- [Sui Typescript SDK](https://sdk.mystenlabs.com/typescript)

### Quickstart

- Create a .env file in the [get-heroes/](./get-heroes/) directory, following the structure of the [.env.example](./get-heroes/.env.example):

```
SUI_NETWORK=https://rpc.testnet.sui.io:443
USER_ADDRESS=0x65391674eb4210940ea98ae451237d9335920297e7c8abaeb7e05b221ee36917
PACKAGE_ID=0xa007ad71e8b80fe7d8fc67d166eb8aa838d74239623218a2287e3f3ffc52c2ca
```

- Run the following commands:

```
cd get-heroes
npm i
npm run test
```

### Instructions

- Notice that the test in the [getHeroes.test.ts](./get-heroes/src/tests/getHeroes.test.ts) file is failing:
  - `Owned Heroes Number`: Validates that the amount of the owned Heroes is exactly 101.

#### 1. Fetch all of the owned objects for the provided address

- Modify the function of the file [src/helpers/getOwnedHeroesIds.ts](./get-heroes/src/helpers/getOwnedHeroesIds.ts) so that it fetches <b>all</b> of the owned Heroes by the address provided in the .env.
- You should use the [suiClient.getOwnedObjects](https://github.com/MystenLabs/ts-sdks/blob/main/packages/typescript/src/client/client.ts#L330-L351) method
- You should use the `filter` argument to fetch only the Hero objects, which have an object type of `${ENV.PACKAGE_ID}::hero::Hero`
- You should use the `hasNextPage` and `nextCursor` part of the response to iterate over all of the available pages
