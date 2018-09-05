pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/introspection/ERC165.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ERCTBDStorage.sol";


/// @title Permissioned
/// @dev base class that gives contracts a sophisticated access control mechanism
contract Permissioned is ERC165, ERCTBDStorage {
    using SafeMath for uint;

    // Random placeholder for irrelevent params in lock id. e.g. `unlock(keccak256(abi.encodePacked("method", param1, ANYTHING, param2)))`
    uint256 internal constant ANYTHING = uint256(keccak256("ANYTHING"));

    /// @dev A convenience modifier that guarentees a condition to be true. eg. `guarentee(unlock('Admin') || unlock('Worker'))`
    /// @param _condition the condition to be met
    modifier guarentee(bool _condition) {
        require(_condition, "Insufficient permissions");
        _;
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // ERC165 0x01ffc9a7
            // solium-disable-next-line operator-whitespace
            interfaceID ==
            this.assignKey.selector ^
            this.assignFullKey.selector ^
            this.revokeKey.selector ^
            this.unlockable.selector ^
            this.getKey.selector; // ERCTBD 0x33f9cb64
    }

    /// @dev does the owner have a valid key for the lock id
    /// @param _id lock id
    /// @param _owner owner address
    /// @return the properties of the requested key as a tuple
    function getKey(bytes32 _id, address _owner) external view returns (bool, bool, uint, uint, uint) {
        return (
            keys[_id][_owner].exists,
            keys[_id][_owner].assignable,
            keys[_id][_owner].start,
            keys[_id][_owner].expiration,
            keys[_id][_owner].uses
        );
    }

    /// @dev is the current block timestamp less than `_expiration`
    /// @param _expiration expiration block timestamp
    /// @return is the expiration valid
    function isValidExpiration(uint _expiration) public view returns (bool valid) {
        // solium-disable-next-line security/no-block-members
        return _expiration == 0 || _expiration >= now;
    }

    /// @dev does the owner have a valid key for the lock id
    /// @param _id lock id
    /// @param _owner owner address
    function unlockable(bytes32 _id, address _owner) public view returns (bool) {
        Key memory key = keys[_id][_owner];
        // solium-disable-next-line security/no-block-members
        return key.exists && isValidExpiration(key.expiration) && key.start <= now;
    }

    /// @dev assign partial or all capabilities from the sender to an account
    /// @param _id lock id
    /// @param _to recipient
    /// @param _assignable can the recipient further assignKey capabilities to other accounts?
    /// @param _start the key's start time (block timestamp)
    /// @param _expiration the key's expiration time (block timestamp)
    /// @param _uses number of times this key can be used (in `unlock(..)`)
    function assignKey(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint _start,
        uint _expiration,
        uint _uses
    ) public
    {
        Key memory key = keys[_id][msg.sender];
        require(key.exists && isValidExpiration(key.expiration), "Invalid key");
        require(key.assignable, "Key is not assignable");

        // solium-disable-next-line security/no-block-members
        require(key.start <= now || _start >= key.start, "Cannot reduce key's future start time");
        require(key.expiration == 0 || (_expiration <= key.expiration && _expiration > 0), "Cannot extend key's expiration");
        require(_expiration == 0 || _start < _expiration, "Start time must be strictly less than expiration");
        require(isValidExpiration(_expiration), "Expiration must be in the future");
        require(key.uses == 0 || (_uses <= key.uses && _uses > 0), "Not enough uses avaiable");

        // solium-disable-next-line security/no-block-members

        Key memory destKey = keys[_id][_to];
        bool possesKey = unlockable(_id, _to) || destKey.start > now;
        require(
            !possesKey || (
                destKey.assignable == _assignable && destKey.expiration == _expiration && (
                    // both in the past or are exactly equal
                    // solium-disable-next-line security/no-block-members
                    (destKey.start <= now && _start <= now) ||
                    destKey.start == _start
                )
            ),
            "Cannot merge into recepeint's key"
        );

        subtractUses(_id,_uses);

        if (unlockable(_id, _to)) {
            if (destKey.uses != 0) {
                if (_uses == 0) {
                    keys[_id][_to].uses = 0;
                } else {
                    keys[_id][_to].uses = destKey.uses.add(_uses);
                }
            }
        } else {
            keys[_id][_to] = Key(true, _assignable, _start, _expiration, _uses);
        }

        emit AssignKey(
            _id,
            msg.sender,
            _to,
            _assignable,
            _start,
            _expiration,
            _uses
        );
    }

    /// @dev assign all capabilities from the sender to an account
    /// @param _id lock id
    /// @param _to recipient
    function assignFullKey(
        bytes32 _id,
        address _to
    ) public
    {
        Key memory key = keys[_id][_to];
        assignKey(
            _id,
            _to,
            key.assignable,
            key.start,
            key.expiration,
            key.uses
        );
    }

    /// @dev revoke the sender's key
    /// @param _id lock id
    function revokeKey(bytes32 _id) public {
        revokeOwnerKey(_id, msg.sender);
    }

    /// @dev Revokes an account's key
    /// @param _id lock id
    /// @param _owner the account address
    function revokeOwnerKey(bytes32 _id, address _owner) internal {
        delete keys[_id][_owner];
        emit RevokeKey(_id, _owner);
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
    ) internal
    {
        require(_expiration == 0 || _start < _expiration, "Start time must be strictly less than expiration");
        require(isValidExpiration(_expiration), "Expiration must be in the future");

        keys[_id][_to].exists = true;
        keys[_id][_to].assignable = _assignable;
        keys[_id][_to].start = _start;
        keys[_id][_to].expiration = _expiration;
        keys[_id][_to].uses = _uses;

        emit AssignKey(
            _id,
            0,
            _to,
            _assignable,
            _start,
            _expiration,
            _uses
        );
    }

    /// @dev Grant full capabilities to account (assignable, no start time, no expiration, infinite uses)
    /// @param _id lock id
    /// @param _to recipient
    function grantFullKey(
        bytes32 _id,
        address _to
    ) internal
    {
        grantKey(
            _id,
            _to,
            true,
            0,
            0,
            0
        );
    }

    /// @dev unlock a lock if sender has a valid key.
    /// @param _id lock id
    function unlock(bytes32 _id) internal returns (bool) {
        if (unlockable(_id, msg.sender)) {
            subtractUses(_id, 1);
            return true;
        }
        return false;
    }

    /// @dev subtract uses from a key, delete the key if it has no uses left.
    /// @param _id lock id
    /// @param _uses uses count to subtract from the key
    function subtractUses(bytes32 _id, uint _uses) private {
        Key memory key = keys[_id][msg.sender];
        if (key.uses > 0) {
            if (key.uses == _uses) {
                delete keys[_id][msg.sender];
            } else {
                keys[_id][msg.sender].uses = keys[_id][msg.sender].uses.sub(_uses);
            }
        }
    }

    function lockId(bytes32 _arg0, bytes32 _arg1) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_arg0, _arg1));
    }

    function lockId(bytes32 _arg0, bytes32 _arg1, bytes32 _arg2) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_arg0, _arg1, _arg2));
    }

    function lockId(bytes32 _arg0, bytes32 _arg1, bytes32 _arg2, bytes32 _arg3) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_arg0, _arg1, _arg2, _arg3));
    }

    function lockId(bytes32 _arg0, bytes32 _arg1, bytes32 _arg2, bytes32 _arg3, bytes32 _arg4) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_arg0, _arg1, _arg2, _arg3, _arg4));
    }

}
