pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title Base class for contracts which deal with fine-grained permissions to their operations.
 * @dev The `Protected` base class manages a set of locks for each resourse/operation and a set of keys for each address.
 *      keys can be created, transfered, used, and expired.
 *      Use the `lock(..)` function to create a new lock.
 *      Use the `only(..)` modifier to lock a resource/operation with a lock.
 */
contract Protected {
    using SafeMath for uint;

    /**
     * Random placeholder value for parameters whose value doesnt matter in the lock id
     * e.g. `lock(keccak256(methodname, param1, ANYTHING, param2))`
     */
    
    uint constant internal ANYTHING = uint(keccak256(abi.encodePacked(uint(this) + 1)));

    struct Key {
        bool exists;
        bool transferable;
        uint expiration; // zero = no expiration
        uint uses; // zero = infinite uses
    }

    //      id                 owner      key
    mapping(bytes32 => mapping(address => Key)) public keys;

    event Transfer(bytes32 indexed _id, address indexed _from, address indexed _to, bool _transferable, uint _expiration, uint _uses);
    event Use(bytes32 indexed _id, address indexed _owner);
    event Revoke(bytes32 indexed _id, address indexed _owner);

    modifier only(bool _condition) {
        require(_condition, "You don't have the permission required for this operation");
        _;   
    }
    
    /**
     * @dev Revoke the sender's key.
     * @param _id lock id.
     */
    function revoke(bytes32 _id) public {
        revokeFrom(_id, msg.sender);
    }

    /**
     * @dev Checks if the expiration date is still valid or the key was expired.
     * @param _expiration the expiration date of the key to check.
     * @return true if the expiration date is still valid, false if already expired.
     */
    function isValidExpiration(uint _expiration) public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return _expiration == 0 || _expiration >= now;
    }

    /**
     * @dev Checks if a key can be used.
     * @param _id lock id.
     * @param _owner the address of the key owner.
     * @return true if the owner has a usable key for the given lock id, false if the key is unusable or not exists.
     */
    function isValidKey(bytes32 _id, address _owner) public view returns (bool) {
        Key memory key = keys[_id][_owner];
        return key.exists && isValidExpiration(key.expiration);
    }

    /**
     * @dev Transfer part of the capabilities of the sender to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param _id lock id.
     * @param _to next owner.
     * @param _transferable can the next owner transfer the key onwards to another account.
     * @param _expiration can only be lower than current expiration.
     * @param _uses can only be smaller than current uses.
     */
    function transferKey(
        bytes32 _id,
        address _to,
        bool _transferable,
        uint _expiration,
        uint _uses
    ) public
    {
        transferKeyFrom(
            _id,
            msg.sender,
            _to,
            _transferable,
            _expiration,
            _uses
        );
    }

    /**
     * @dev Transfer all of the capabilities of the sender to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param _id lock id.
     * @param _to next owner.
     */
    function transferAll(bytes32 _id, address _to) public {
        transferAllFrom(_id, msg.sender, _to);
    }

    /**
     * @dev Revoke a given key making it non existent.
     * @param _id lock id,
     * @param _owner the owner of the key.
     */
    function revokeFrom(bytes32 _id, address _owner) internal {
        keys[_id][_owner].exists = false;
        emit Revoke(_id, _owner);
    }

    /**
     * @dev Sets a key for a lock id for an address.
     * @notice This function should be used only by the contract itself to create new keys.
     * @notice This function overwrites the existing key (if there is one).
     * @param _id lock id.
     * @param _to the new key owner.
     * @param _transferable will the new key be transferable.
     * @param _expiration expiration date (in seconds) for the key.
     * @param _uses uses count for the key.
     */
    function setKey (
        bytes32 _id,
        address _to,
        bool _transferable,
        uint _expiration,
        uint _uses
        ) internal
    {
        keys[_id][_to] = Key(true, _transferable, _expiration, _uses);

        emit Transfer(
            _id,
            this,
            _to,
            _transferable,
            _expiration,
            _uses
        );
    }

    /**
     * @dev Transfer part of the capabilities of the owner to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param _id lock id.
     * @param _from current owner.
     * @param _to next owner.
     * @param _transferable can the next owner transfer the key onwards to another account.
     * @param _expiration can only be lower than current expiration.
     * @param _uses can only be smaller than current uses.
     */
    function transferKeyFrom(
        bytes32 _id,
        address _from,
        address _to,
        bool _transferable,
        uint _expiration,
        uint _uses
        ) internal
    {
        Key memory key = keys[_id][_from];
        require(isValidKey(_id, _from), "Specified key is invalid");
        require(key.transferable, "Sender's key isn't a transferable key");
        require(key.expiration == 0 || _expiration <= key.expiration, "Your key has shorter expiration date than required");
        require(key.uses == 0 || _uses <= key.uses, "You don't have enough uses in your key");
        // solium-disable-next-line security/no-block-members
        require(isValidExpiration(_expiration), "Please specify expiration date in the future");

        require(
            !isValidKey(_id, _to) || (keys[_id][_to].transferable == _transferable && keys[_id][_to].expiration == _expiration),
            "Another matching key already exists for the receiver, please revoke it before transfer"
            );
        
        if (key.uses > 0) {
            if (_uses == key.uses) {
                delete keys[_id][_from];
            } else {
                keys[_id][_from].uses = keys[_id][_from].uses.sub(_uses);
            }
        }

        if (isValidKey(_id, _to)) {
            if (keys[_id][_to].uses != 0) {
                if (_uses == 0) {
                    keys[_id][_to].uses = 0;
                } else {
                    keys[_id][_to].uses = keys[_id][_to].uses.add(_uses);
                }
            }
        } else {
            keys[_id][_to] = Key(true, _transferable, _expiration, _uses);
        }

        emit Transfer(
            _id,
            _from,
            _to,
            _transferable,
            _expiration,
            _uses
        );
    }

    /**
     * @dev Transfer all of the capabilities of the owner to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param _id lock id.
     * @param _from current owner.
     * @param _to next owner.
     */
    function transferAllFrom(bytes32 _id, address _from, address _to) internal {
        Key memory key = keys[_id][_from];
        transferKeyFrom(
            _id,
            _from,
            _to,
            true,
            key.expiration,
            key.uses
        );
    }

    /**
     * @dev A function that unlock a function lock .
            Unlock function returns a boolean, which can be used with other unlock function calls and checked together with the `only` modifier.
            This allows us to create complex boolean predicates:
            ```
            function myMethod()
                only((unlock("louis") || unlock("tom")) && unlock("jerry"))
            {
                // restricted to: (louis || tom) && jerry
            }
            ```
     * @param _id the id of the lock which the user want to unlock.
     * @return true if the key was used, false no matching key was found.
     */

    function unlock(bytes32 _id) internal returns (bool) {
        bool used = false;
        Key memory key = keys[_id][msg.sender];
        
        if (isValidKey(_id, msg.sender)) {
            if (key.uses == 1) {
                delete keys[_id][msg.sender];
            } else if (key.uses > 1) {
                keys[_id][msg.sender].uses --;
            }
            emit Use(_id, msg.sender);
            used = true;
        }
        return used;
    }
}
