## Sui & Move Bootcamp

### Data Ingestion Approaches

##### What you will learn in this module

This section demonstrates two different approaches for ingesting and indexing data from the Sui blockchain, each with its own use cases and advantages.

## 1. Custom Indexer with Data Ingestion Framework

The first approach utilizes Sui's data ingestion framework to create a custom indexer that processes blockchain data at the checkpoint level:

Key features:
- Monitors and processes checkpoints in real-time
- Extracts transaction data from each checkpoint
- Implements custom filtering logic
- Supports multiple data sources:
  - Smart contract events
  - Transaction effects
  - Balances changes and trx gas fees monitoring
  - etc.

This approach is particularly useful when you need:
- Fine-grained control over data processing
- Custom filtering logic
- Access to all transaction data
- Real-time processing at checkpoint level

## 2. Event-Based Indexer with TypeScript Generator

The second approach uses a specialized TypeScript tool to automatically generate:
- TypeScript types for Move events
- Database migration files
- Query API for event data

Key features:
- Automatic type generation from Move events
- Database schema generation
- Built-in query API
- Based on `sui_queryEvents` RPC call
- NPM package integration

This approach is ideal when:
- Working exclusively with smart contract events
- Need quick setup and deployment
- Want type-safe event handling
- Require standard database integration

## Comparison and Use Cases

### Custom Indexer
- More flexible and powerful
- Requires more setup and maintenance
- Better for complex data processing
- Suitable for custom data sources

### Event-Based Indexer
- Faster to implement
- Less maintenance required
- Focused on event data
- Better for standard use cases

---
### Useful Links

 - [Custom Indexer](https://docs.sui.io/guides/developer/advanced/custom-indexer#local-reader)
 - [Using Events](https://docs.sui.io/guides/developer/sui-101/using-events#monitoring-events)
 - [Sui Events Indexer - TS](https://www.buidly.com/blog/sui-events-indexer)
