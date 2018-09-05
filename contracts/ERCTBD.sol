pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/introspection/ERC165.sol";
import "./ERCTBDInterface.sol";


/// @title ERCTBD - Access Control Interface
/// @dev contract for access control mechanism
contract ERCTBD is ERC165, ERCTBDInterface {
    struct Key {
        bool exists;
        bool assignable;
        uint start;
        uint expiration;
        uint uses;
    }

    /// @dev Grant capabilities to account (overwrites existing key)
    /// @param _id lock id
    /// @param _to recipient
    /// @param _assignable can the recipient further assignKey his capabilities to other accounts?
    /// @param _start the key's start time (block timestamp)
    /// @param _expiration the key's expiration time (block timestamp)
    /// @param _uses number of times this key can be used (in `unlock(..)`)
    function grantKey(
        bytes32 _id, 
        address _to, 
        bool _assignable, 
        uint _start, 
        uint _expiration, 
        uint _uses
        ) internal;

    /// @dev Grant full capabilities to account (assignable, no start time, no expiration, infinite uses)
    /// @param _id lock id
    /// @param _to recipient
    function grantFullKey(bytes32 _id, address _to) internal;

    /// @dev unlock a lock if sender has a valid key.
    /// @param _id lock id
    function unlock(bytes32 _id) internal returns (bool);
}
