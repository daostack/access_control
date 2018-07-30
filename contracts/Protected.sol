pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Base class for contracts which deal with fine-grained permissions to their operations.
 * @dev The `Protected` base class manages a set of locks for each resourse/operation and a set of keys for each address.
 *      keys can be created, transfered, used, and expired.
 *      Use the `lock(..)` function to create a new lock.
 *      Use the `only(..)` modifier to lock a resource/operation with a lock.
 */
contract Protected {
    using Math for uint;
    using SafeMath for uint;

    /**
     * Random placeholder value for parameters whose value doesnt matter in the lock id
     * e.g. `lock(keccak256(methodname, param1, ANYTHING, param2))`
     */
    uint internal constant ANYTHING = 0x62c7a977c34f9fcd712a23dbe94695f0ca4eaaaaf82c52df590c848939735942 ;

    struct Key {
        bool exists;
        bool transferable;
        uint expiration; // zero = no expiration
        uint uses; // zero = infinite uses
    }

    //      id                 owner      key
    mapping(bytes32 => mapping(address => Key)) public keys;

    event Lock(bytes32 indexed id);
    event Transfer(bytes32 indexed id, address indexed from, address indexed to, bool transferable, uint expiration, uint uses);
    event Use(bytes32 indexed id, address indexed owner);
    event Revoke(bytes32 indexed id, address indexed owner);

    /**
     * @dev Create a new key for a new lock. The owner of the key is the contract itself.
     * @notice The convention for lock ids is:
     *           - restricting a method: `lock(methodName)`
     *           - restricting to specific params: `lock(keccak256(methodName, param1, param2))`
     *           - use ANYTHING for irrelevent parameters: `lock(keccak256(methodName, param1, ANYTHING, param3))`
     *           - traling `ANYTHING`s are implied: use `lock(keccak256(methodName, param1))` instead of `lock(keccak256(methodName, param1, ANYTHING))`
     * @param id unique lock id
     * @param expiration key can be used only before expiration time.
     * @param uses key can be used only #uses times.
     */
    function lock(
        bytes32 id
    ) internal {
        require(!keys[id][this].exists);

        keys[id][this].exists = true;
        keys[id][this].transferable = true;

        emit Lock(id);
    }

    /**
     * @dev Destroy a given key making it non existent.
     * @param id lock id,
     * @param owner the owner of the key.
     */
    function revoke(bytes32 id, address owner) internal {
        keys[id][owner].exists = false;
        emit Revoke(id, owner);
    }

    /**
     * @dev Destroy the sender's key.
     * @param id lock id,
     */
    function revoke(bytes32 id) public {
        revoke(id, msg.sender);
    }

    /**
     * @dev Transfer part of the capabilities of the owner to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param id lock id.
     * @param from current owner.
     * @param to next owner.
     * @param transferable can the next owner transfer the key onwards to another account.
     * @param expiration can only be lower than current expiration.
     * @param uses can only be smaller than current uses.
     */
    function transferKeyFrom(
        bytes32 id,
        address from,
        address to,
        bool transferable,
        uint expiration,
        uint uses
    ) internal {
        Key memory key = keys[id][from];
        require(key.exists);
        require(key.transferable);
        require(expiration != 0 || key.expiration == 0);
        require(expiration <= key.expiration);
        require(uses != 0 || key.uses == 0);
        require(uses <= key.uses);

        if (uses > 0 && uses == key.uses) {
            keys[id][from].exists = false;
        } else {
            keys[id][from].uses = keys[id][from].uses.sub(uses);
        }

        if(keys[id][to].exists) {
            // Merge capabilities (note: this can be a problem since it might expand capabilities)
            keys[id][to].transferable = keys[id][to].transferable || transferable;
            keys[id][to].expiration = keys[id][to].expiration.max256(expiration);
            keys[id][to].uses = keys[id][to].uses.add(uses);
        } else {
            keys[id][to].exists = true;
            keys[id][to].transferable = transferable;
            keys[id][to].expiration = expiration;
            keys[id][to].uses = uses;
        }

        emit Transfer(id, from, to, transferable, expiration, uses);
    }

    /**
     * @dev Transfer part of the capabilities of the sender to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param id lock id.
     * @param to next owner.
     * @param transferable can the next owner transfer the key onwards to another account.
     * @param expiration can only be lower than current expiration.
     * @param uses can only be smaller than current uses.
     */
    function transferKey(
        bytes32 id,
        address to,
        bool transferable,
        uint expiration,
        uint uses
    ) public {
        transferKeyFrom(
            id,
            msg.sender,
            to,
            transferable,
            expiration,
            uses
        );
    }

    /**
     * @dev Transfer all of the capabilities of the owner to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param id lock id.
     * @param from current owner.
     * @param to next owner.
     */
    function transferAllFrom(bytes32 id, address from, address to) internal {
        Key memory key = keys[id][from];
        transferKeyFrom(id, from, to, true, key.expiration, key.uses);
    }

    /**
     * @dev Transfer all of the capabilities of the sender to another account.
     * @notice if the next owner already has a key for this lock id, the keys will be merged into a single key.
     * @param id lock id.
     * @param to next owner.
     */
    function transferAll(bytes32 id, address to) public {
        transferAllFrom(id, msg.sender, to);
    }

    /**
     * @dev A modifier that locks a function with lock ids.
            The lock ids are "ORed" together, meaning the lock can be opened by a key that unlocks any one of the ids.
            This allows us to create complex boolean predicates:
            ```
            function myMethod()
                only(["louis", "tom"])
                only(["jerry"])
            {
                // restricted to: (louis || tom) && jerry
            }
            ```
     * @notice the modifier tries each key in order until one matches, the key that matches will be used one time. if none match, a revert occurs.
     * @param ids array of lock ids.
     */
    modifier only(bytes32[] ids) {
        bool used = false;
        for(uint i = 0 ; i < ids.length; i++){
            bytes32 id = ids[i];
            Key memory key = keys[id][msg.sender];
            if (
                key.exists &&
                (key.expiration == 0 || key.expiration >= now)
            ) {
                if (key.uses == 1) {
                    keys[id][msg.sender].exists = false;
                } else if (key.uses > 1){
                    keys[id][msg.sender].uses --;
                }
                emit Use(id, msg.sender);
                used = true;
                break;
            }
        }
        if(!used) {
            require(false, "No matching key was found");
        }

        _;
    }
}



