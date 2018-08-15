pragma solidity ^0.4.24;

import "./EIPTBDInterface.sol";


/**
 * @title EIPTBD - Access Control
 * @dev contract interface for access control mechanism
 */
contract EIPTBD is EIPTBDInterface {
    
    // Random placeholder for irrelevent params in lock id. e.g. `unlock(keccak256(abi.encodePacked("method", param1, ANYTHING, param2)))`
    uint internal constant ANYTHING = uint(keccak256("ANYTHING"));

    struct Key {
        bool exists;
        bool assignable;
        uint expiration; // zero = no expiration
        uint uses; // zero = infinite uses
    }

    //      id                 owner      key
    mapping(bytes32 => mapping(address => Key)) public keys;

    /**
     * @dev A convenience modifier that guarentees a condition to be true. eg. `guarentee(unlock('Admin') || unlock('Worker'))`
     * @param _condition the condition to be met
     */
    modifier guarentee(bool _condition) {
        require(_condition, "Insufficiant permissions");
        _;
    }

    /**
     * @dev unlock a lock if sender has a valid key.
     * @param _id lock id
     */
    function unlock(bytes32 _id) internal returns (bool);

    /**
     * @dev Grant capabilities to account
     * @param _id lock id
     * @param _to recipient
     * @param _assignable can the recipient further assign his capabilities to other accounts?
     * @param _expiration the key's expiration time (block number)
     * @param _uses number of times this key can be used (in `unlock(..)`)
     */
    function grantKey(bytes32 _id, address _to, bool _assignable, uint _expiration, uint _uses) internal;

    /**
     * @dev Grant full capabilities to account (assignable, no expiration, infinite uses)
     * @param _id lock id
     * @param _to recipient
     */
    function grantFullKey(bytes32 _id, address _to) internal;
}
