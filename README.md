![AUR](https://img.shields.io/aur/license/yaourt.svg)

# Access Control

[Capability-based access control](https://en.wikipedia.org/wiki/Capability-based_security) for Ethereum smart contracts.

## Get started

1. `npm install --save @daostack/access_control`
2.  Use it in your smart contract
    ```javascript
    import "@daostack/access_control/contracts/Protected.sol";

    contract Foo is Protected {
        // Foo stuff...
    }
    ```

Check out the [documentation](https://daostack.github.io/access_control/) for more!

## Concept
The basic idea is that there are a set of "locks"/"topics" each with a set of "keys". A contract can protects one of it's methods with a lock (or more) such that anyone with the appropriate key can use it to access this method.
Each key can have an expiration time, # of uses. Accounts can also transfer some (or all) of their capabilities to other accounts if allowed. Initially the contract itself has a "master key" (infinite uses, no expiration), and then it can pass some partial capabilities to the desired accounts.

Features:

- Can define a number of uses & expiration date on keys and if to enable the key to be transfrred.
- Accounts can transfer partial (or full) abillites to other accounts (if allowed).
- We can use advanced lock ids to lock a method even on specific parameters, enforce ordering, or other properties (see example).
- Can define complex boolean predicates to protect methods.
- No performance loss over hand-crafted mechanisms.

Benefits:

- Declarative policy (no more sprinkling ifs all over the codebase)
- Easy control flow (ordering, timing, number of function calls) restrictions (e.g. only allowed to call B after calling A twice within 2 days).
- Allows accounts to call functions themselves instead of delegating through other contracts.
- Generalized logging mechanism: key usage events can be queried by clients to know whether a method was called and by which account, key revocations can be used to know when users no longer have access to a method.
- Easier security since we need to verify less code.


## Contribute

1. `git clone git@github.com:daostack/access_control.git && cd access_control`
2. `npm install` / `yarn`

Available Commands:

- `npm run ganache`
- `npm run lint`
- `npm run test`
- `npm run build`
- `npm run docs<update|build|deploy|preview>`
