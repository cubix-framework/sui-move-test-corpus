# Admin Authorization and Referent IDs

In this section, you will deepen your understanding of authorization patterns and referent ID management in Move smart contracts. You will learn how to implement and compare different admin authorization mechanisms—including Access Control Lists (ACL), capability-based, and signature-based approaches—and how to securely link capabilities to shared objects using referent IDs. These skills are essential for building robust, secure, and maintainable smart contracts on Sui.

## Project Structure

This exercise is organized into several modules, each focusing on a different aspect of authorization or referent ID management:
- `admin_action/move/sources/acl.move`: Implements ACL-based authorization.
- `admin_action/move/sources/admin_cap.move`: Demonstrates capability-based authorization using `AdminCap`.
- `admin_action/move/sources/signature.move`: Explores signature-based authorization and replay protection.
- `satchel/sources/satchel.move`: Focuses on referent ID fixes and secure linking of capabilities to shared objects.

Each module is accompanied by targeted tasks and tests to help you practice and verify your understanding.

## Tasks Overview

### 1. Access Control List (ACL) Authorization
In `admin_action/move/sources/acl.move`:
- Implement authorization in the `mint` function using the `AccessControlList`

### 2. Capability-Based Authorization
In `admin_action/move/sources/admin_cap.move`:
- Implement authorization in the `mint` function using the `AdminCap`

### 3. Signature-Based Authorization
In `admin_action/move/sources/signature.move`:
- Replace the `BE_PUBLIC_KEY` constant with your own public key,
and `sig` in the test with your signature generated with _create-signature/sign.ts_.
Running `sui move test` should fail with `EExpectedFailure`.
- Modify the `mint` function to include the `Counter` in the signed message
- Inside _sign.ts_, set `WITH_COUNTER` to `true` to generate signatures that include the counter
  - Use this signature in the `test_replay` test

### 4. Referent ID Fixes in Satchel
In `satchel/sources/satchel.move`:
- Link the `SatchelCap` with the `SharedSatchel` it controls
- Implement proper authorization in `add_scroll` and `remove_scroll` functions
- Make the `Borrow` hot-potato specific to a particular `SharedSatchel`

## Useful Links

- [Capability Pattern](https://move-book.com/programmability/capability.html)
