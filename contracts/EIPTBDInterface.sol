pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


/**
 * @title EIPTBDInterface - Access Control Interface
 * @dev base inteface for access control mechanism
 */
interface EIPTBDInterface {

    event AssignKey(bytes32 indexed _id, address indexed _from, address indexed _to, bool _assignable, uint _expiration, uint _uses);

    event RevokeKey(bytes32 indexed _id, address indexed _owner);

    /**
     * @dev transfer partial or all capabilities from the sender to an account
     * @param _id lock id
     * @param _to recipient
     * @param _assignable can the recipient further assign capabilities to other accounts?
     * @param _expiration the key's expiration time (block number)
     * @param _uses number of times this key can be used (in `unlock(..)`)
     */
    function assignKey(bytes32 _id, address _to, bool _assignable, uint _expiration, uint _uses) external;

    /**
     * @dev transfer all capabilities from the sender to an account
     * @param _id lock id
     * @param _to recipient
     */
    function assignFullKey(bytes32 _id, address _to) external;

    /**
     * @dev revoke the sender's key
     * @param _id lock id
     */
    function revokeKey(bytes32 _id) external;

    /**
     * @dev does the owner have a valid key for the lock id
     * @param _id lock id
     * @param _owner owner address
     */
    function unlockable(bytes32 _id, address _owner) external view returns (bool);
    
    /**
     * @dev returns locks of a function
     * @param _functionId function id 
     * @return array of lock ids for each "lock set" required to unlock the function
     * @notice all locks in a "lock set" are ORed, meaning open one of them is enough to unlock  the set
     * @notice all "lock sets" are ANDed, meaning it is required to unlock them all in order to unlock the function
     */
    function getLocksForFunction(bytes4 _functionId) external view returns (bytes32[][] lockSets);
}
