pragma solidity ^0.4.24;


/// @title ERCTBDInterface - Access Control Interface
/// @dev basic inteface for access control mechanism
/// Note: the ERC-165 identifier for this interface is 0x0b74c80f.
interface ERCTBDInterface {

    event AssignKey(
        bytes32 indexed _id, 
        address indexed _from, 
        address indexed _to, 
        bool _assignable, 
        uint80 _start, 
        uint80 _expiration, 
        uint80 _uses
    );

    event RevokeKey(bytes32 indexed _id, address indexed _owner);

    /// @dev assign partial or all capabilities from the sender to an account
    /// @param _id lock id
    /// @param _to recipient
    /// @param _assignable can the recipient further assign capabilities to other accounts?
    /// @param _start the key's start time (block number)
    /// @param _expiration the key's expiration time (block number)
    /// @param _uses number of times this key can be used (in `unlock(..)`)
    function assignKey(bytes32 _id, address _to, bool _assignable, uint80 _start, uint80 _expiration, uint80 _uses) external;

    /// @dev assign all capabilities from the sender to an account
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

    /// @dev does the owner have a valid key for the lock id
    /// @param _id lock id
    /// @param _owner owner address
    /// @return the properties of the requested key as a tuple
    function getKey(bytes32 _id, address _owner) external view returns (bool, bool, uint80, uint80, uint80);
}