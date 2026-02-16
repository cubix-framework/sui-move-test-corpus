# [I5]: Kiosk Rules

## What You Will Learn

In this section, you will learn how to implement and enforce advanced Kiosk rules for NFT trading in Move. You will:

- Set up transfer policies that enforce royalties, personal kiosk usage, and locking rules
- Implement logic for personal kiosks and secure item placement
- Handle purchases that respect royalty and locking requirements

By the end, you will be able to design and test NFT marketplaces with robust rule enforcement and royalty mechanisms in Move.

In this section we will work with the use of common Kiosk rules that are used to force royalties
when trading Swords.

## Sword Contract

This project uses the same Sword contract as in [I4]. The contract (`sword.move`) is a simple NFT implementation that creates swords with the following properties:
- Name
- Damage value
- Special effects (as a vector of strings)
- Display metadata (name, image URL, description)

## Project Structure

The codebase consists of several key components:

1. `src/publish.ts` - Handles rules and package publishing and policy creation
2. `src/kiosk.ts` - Implements kiosk-related operations
3. `src/create-sword.ts` - Contains functionality for creating new sword NFTs
4. `src/consts.ts` - Contains constants and configuration
5. `src/kiosk.test.ts` - Contains tests for kiosk operations

## Tasks to Complete

![Kiosk Rules](kiosk-rules.png)
There are three main tasks to implement in this project:

### 1. Set Transfer Policy Rules
In `src/publish.ts`, implement the transfer policy rules in the `createPolicy` function. The policy should include:
- Personal kiosk rule
- Royalty rule
- Lock rule

### 2. Create Personal Kiosk
In `src/kiosk.ts`, implement the `createPersonalKiosk` function to make a kiosk personal. This involves:
- Creating a new kiosk
- Making it personal using the appropriate Move call(s)

### 3. Implement Purchase Rules
In `src/kiosk.ts`, complete the `purchase` function to handle sword purchases by:
- Putting the sword in the buyer's PersonalKiosk (personal_kiosk_rule)
- Locking the sword in the kiosk (kiosk_lock_rule)
- Paying royalties (royalty_rule)

## Useful Links

- [Sui Kiosk](https://docs.sui.io/standards/kiosk)
