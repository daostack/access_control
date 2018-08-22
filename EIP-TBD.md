---
eip: <to be assigned>
title: Modular Access Control Mechanism
author: Matan Tsuberi <mtsuberi@daostack.io>, Ben Kaufman <ben@daostack.io>, Adam Levi <adam@daostack.io>, Oren Sokolowsky <oren@daostack.io>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2018-08-dd (hopefully this month)
requires: 165
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

Standard access control mechanism for smart contracts.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

This EIP presents a generalized mechanism for access control on smart contracts, enabling the use of complex boolean expressions for limiting access to contract's functions. The mechanism utilizes the idea of ["keys"](https://en.wikipedia.org/wiki/Capability-based_security) for the access limitations. Keys could be transferable, expirable, limited to certain amount of uses or limited to certain fucntion parameters use.

## Motivation

<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Access control is one of the basic components most smart contract applications and frameworks need to have. The ability to limit the access for calling a function to a specific EOA or smart contract account is vital for most systems. The core logic for the access control of a smart contract has a great importance as it is usually the main security risk a contract may have, and if compromised, it can cause fatal issue for the entire system.
There is a vast number of use cases requiring access management for smart contracts. A few popular examples can be:

- Ownable - This is probably the most popular access control mechanism used in the Ethereum space. OpenZeppelin's implementation can be found [here](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol).

- Membership Management - There are much efforts for managing membership on the Ethereum blockchain. A full detailed rationale for that can be found on [EIP-1261 - Membership Verification Token](https://eips.ethereum.org/EIPS/eip-1261). However, this creates a duplication of effort as membership management is just a single aspect of access controll mechanism. In addition, the current effort lacks some basic properties such as expiration and transferability of memberships.

- DAO operations - There are multiple teams working in the DAO space, all facing the problem of access control in a DAO. Thus, there is a lot of duplicated work on the subject with each having its own pros and cons. However, non of them has found a mechanism generalized enough to answer all possible future needs of DAOs.

There is a strong need for an effective generalized way of managing access rights, most importantly in a trustless manner. We would like to propose a generalized mechanism for access control in smart contracts to provide easier interoperability, reduce security risks, and minimize the duplicated effort of teams working in the subject.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Every ERC-TBD compliant contract MUST implement the `ERCTBD` and `ERC165` interfaces** (subject to "caveats" below):

```solidity
pragma solidity ^0.4.24;


/// @title ERCTBDInterface - Access Control Standard
/// Note: the ERC-165 identifier for this interface is 0xef07a1f8.
interface ERCTBDInterface {

    event AssignKey(bytes32 indexed _id, address indexed _from, address indexed _to, bool _assignable, uint80 _expiration, uint80 _uses);
    event RevokeKey(bytes32 indexed _id, address indexed _owner);

    /// @dev transfer partial or all capabilities from the sender to an account
    /// @param _id lock id
    /// @param _to recipient
    /// @param _assignable can the recipient further assign capabilities to other accounts?
    /// @param _expiration the key's expiration time (block number)
    /// @param _uses number of times this key can be used (in `unlock(..)`)
    function assignKey(bytes32 _id, address _to, bool _assignable, uint80 _expiration, uint80 _uses) external;

    /// @dev transfer all capabilities from the sender to an account
    /// @param _id lock id
    /// @param _to recipient
    function assignFullKey(bytes32 _id, address _to) external;

    /// @dev revoke the sender's key
    /// @param _id lock id
    function revokeKey(bytes32 _id) external;

    /// @dev does the owner have a valid key for the lock id
    /// @param _id lock id
    /// @param _owner owner address
    function unlockable(bytes32 _id, address _owner) external view returns (bool);
}

/// @title ERCTBD - Access Control Interface
/// @dev contract for access control mechanism
contract ERCTBD is ERC165, ERCTBDInterface {
    struct Key {
        bool exists;
        bool assignable;
        uint80 expiration;
        uint80 uses;
    }

    /// @dev Grant capabilities to account (overwrites existing key)
    /// @param _id lock id
    /// @param _to recipient
    /// @param _assignable can the recipient further assignKey his capabilities to other accounts?
    /// @param _expiration the key's expiration time (block timestamp)
    /// @param _uses number of times this key can be used (in `unlock(..)`)
    function grantKey(bytes32 _id, address _to, bool _assignable, uint80 _expiration, uint80 _uses) internal;

    /// @dev Grant full capabilities to account (assignable, no expiration, infinite uses)
    /// @param _id lock id
    /// @param _to recipient
    function grantFullKey(bytes32 _id, address _to) internal;

    /// @dev unlock a lock if sender has a valid key.
    /// @param _id lock id
    function unlock(bytes32 _id) internal returns (bool);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
```

The _storage extention_ is RECOMMENDED for ERC-TBD smart contracts (see "caveats", below). This contains the RECOMMENDED data structure for storing the access "keys".

```solidity
/// @title ERCTBDStorage - Access Control, RECOMMENDED data structure
contract ERCTBDStorage is ERCTBD {
    mapping(bytes32 => mapping(address => Key)) public keys;
}
```

### Caveats

The 0.4.24 Solidity interface grammar is not expressive enough to document the ERC-TBD standard. A contract which complies with ERC-TBD MUST also abide by the following:

- Solidity issue #3412: The above interfaces include explicit mutability guarantees for each function. Mutability guarantees are, in order weak to strong: `payable`, implicit nonpayable, `view`, and `pure`. Your implementation MUST meet the mutability guarantee in this interface and you MAY meet a stronger guarantee. For example, a `payable` function in this interface may be implemented as nonpayble (no state mutability specified) in your contract. We expect a later Solidity release will allow your stricter contract to inherit from this interface, but a workaround for version 0.4.24 is that you can edit this interface to add stricter mutability before inheriting from your contract.
- Solidity issue #2330: If a function is shown in this specification as `external` then a contract will be compliant if it uses `public` visibility. As a workaround for version 0.4.20, you can edit this interface to switch to `public` before inheriting from your contract.

_If a newer version of Solidity allows the caveats to be expressed in code, then this EIP MAY be updated and the caveats removed, such will be equivalent to the original specification._

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

There are many approaches which were developed to create an access control mechanism, but each focuses on a relatively specific use case. We tried to create a generalized mechanism allowing for all uses cases to be implemented, while keeping the gas efficiency similar to a more dedicated solution.
We chose to use the concept of "Keys" with the certain properties of: uses limit, expiration time, and (re-)assignablity. This approach allows the use of complex boolean expressions for limiting access to a function such as allowing an account to call a certain function (or multiple functions) 2 times until the end of next month and possibly assign that right to another account.
A more concrete example could be for "Ownership" of a contract. A common use case for the ("Ownable" contract)[ADD LINK] are "safty backdoors" - functions which enable the "owner" of the contract do controversial changes in crisis times. Most teams promise to eliminate their access to those backdoors after their project gets mature enogh, but this requires to trust the team to stand up for this promise. The "Ownable" contract pattern, thus, could benefit from the addition of a trustless expiration date, removing the need of trusting the teams to give up on their "safety backdoors" access when their project matures.

The proposed interface contains functions to allow utilizing the full capabilities of the properties of a key. Which are the ability to grant (by the contract), assign to other account, revoke, and use a key. This also keeps the option for implementations to have their own characteristics and suitable behaviour. For example, it is possible for an implementation to use block number for keys expiration, instead of timestamps. For gas optimizations, we also used 0 values to "disable" the use of certain features, this makes keys which doesn't have, for example, expiration time to have similar gas consumption to another solution with no expiration parameter at all.

## Backwards Compatibility

<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

There are no backwards compatibility concerns.

## Test Cases

<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

DAOstack ERC-TBD implementation includes test cases written using Truffle.

## Implementation

<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

DAOStack full implementation is available [here](ADD LINK)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
