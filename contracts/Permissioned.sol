pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/introspection/ERC165.sol";
import "./ERCTBDStorage.sol";


/// @title Permissioned
/// @dev base class that gives contracts a sophisticated access control mechanism
contract Permissioned is ERC165, ERCTBDStorage {
    using SafeMath for uint;
    
    // Random placeholder for irrelevent params in lock id. e.g. `unlock(keccak256(abi.encodePacked("method", param1, ANYTHING, param2)))`
    uint internal constant ANYTHING = uint(keccak256("ANYTHING"));

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
            this.unlockable.selector; // ERCTBD 0xef07a1f8
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
        return key.exists && isValidExpiration(key.expiration);
    }

    /// @dev transfer partial or all capabilities from the sender to an account
    /// @param _id lock id
    /// @param _to recipient
    /// @param _assignable can the recipient further assignKey capabilities to other accounts?
    /// @param _expiration the key's expiration time (block timestamp)
    /// @param _uses number of times this key can be used (in `unlock(..)`)
    function assignKey(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint _expiration,
        uint _uses
    ) public
    {
        Key memory key = keys[_id][msg.sender];
        require(key.exists && isValidExpiration(key.expiration), "Invalid key");
        require(key.assignable, "Key is not assignable");
        require(key.expiration == 0 || _expiration <= key.expiration, "Cannot extend key's expiration");
        require(key.uses == 0 || _uses <= key.uses, "Not enough uses avaiable");
        require(isValidExpiration(_expiration), "Expiration must be in the future");

        require(
            !unlockable(_id, _to) || (keys[_id][_to].assignable == _assignable && keys[_id][_to].expiration == _expiration),
            "Cannot merge into recepeint's key"
        );

        subtractUses(_id,_uses);

        if (unlockable(_id, _to)) {
            if (keys[_id][_to].uses != 0) {
                if (_uses == 0) {
                    keys[_id][_to].uses = 0;
                } else {
                    keys[_id][_to].uses = keys[_id][_to].uses.add(_uses);
                }
            }
        } else {
            setKey(_id, _to, _assignable, _expiration, _uses);
        }

        emit AssignKey(
            _id,
            msg.sender,
            _to,
            _assignable,
            _expiration,
            _uses
        );
    }

    /// @dev transfer all capabilities from the sender to an account
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
        deleteKey(_id, _owner);
        emit RevokeKey(_id, _owner);
    }

    /// @dev Grant capabilities to account (overwrites existing key)
    /// @param _id lock id
    /// @param _to recipient
    /// @param _assignable can the recipient further assignKey his capabilities to other accounts?
    /// @param _expiration the key's expiration time (block timestamp)
    /// @param _uses number of times this key can be used (in `unlock(..)`)
    function grantKey(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint _expiration,
        uint _uses
    ) internal
    {
        require(isValidExpiration(_expiration), "Expiration must be in the future");

        setKey(_id, _to, _assignable, _expiration, _uses);

        emit AssignKey(
            _id,
            0,
            _to,
            _assignable,
            _expiration,
            _uses
        );
    }

    /// @dev Grant full capabilities to account (assignable, no expiration, infinite uses)
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
                deleteKey(_id, msg.sender);
            } else {
                keys[_id][msg.sender].uses = keys[_id][msg.sender].uses.sub(_uses);
            }
        }
    }

    function setKey(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint _expiration,
        uint _uses
    ) private 
    {
        Key memory key = keys[_id][_to];

        if (!key.exists) {
            keys[_id][_to].exists = true;
        }

        if (_assignable != key.assignable) {
            keys[_id][_to].assignable = _assignable;
        }

        if (_expiration != key.expiration) {
            keys[_id][_to].expiration = _expiration;
        }
        
        if (_uses != key.uses) {
            keys[_id][_to].uses = _uses;
        }
    }

    function deleteKey(bytes32 _id, address _to) private {
        Key memory key = keys[_id][_to];
        
        keys[_id][_to].exists = false;
        
        if (key.assignable) {
            keys[_id][_to].assignable = false;
        }

        if (key.expiration != 0) {
            keys[_id][_to].expiration = 0;
        }
        
        if (key.uses != 0) {
            keys[_id][_to].uses = 0;
        }
    }
}
