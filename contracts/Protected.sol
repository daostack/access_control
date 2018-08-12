pragma solidity ^0.4.24;

import "zeppelin-solidity/contracts/math/Math.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

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
    uint internal constant ANYTHING = uint(keccak256(toBytes(uint(this) + 1)));

    struct Key {
        bool exists;
        bool transferable;
        uint expiration; // zero = no expiration
        uint uses; // zero = infinite uses
    }

    //      id                 owner      key
    mapping(bytes32 => mapping(address => Key)) public keys;

    event Transfer(bytes32 indexed id, address indexed from, address indexed to, bool transferable, uint expiration, uint uses);
    event Use(bytes32 indexed id, address indexed owner);
    event Revoke(bytes32 indexed id, address indexed owner);

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

    function setKey (
        bytes32 id,
        address to,
        bool transferable,
        uint expiration,
        uint uses) internal {
        keys[id][to].exists = true;
        keys[id][to].transferable = transferable;
        keys[id][to].expiration = expiration;
        keys[id][to].uses = uses;

        emit Transfer(id, this, to, transferable, expiration, uses);
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
        require(isValidKey(key.exists, key.expiration), "Specified key is invalid");
        require(key.transferable, "Sender's key isn't a transferable key");
        require(key.expiration == 0 || expiration <= key.expiration, "Your key has shorter expiration date than required");
        require(key.uses == 0 || uses <= key.uses, "You don't have enough uses in your key");
        // solium-disable-next-line security/no-block-members
        require(isValidExpiration(expiration), "Please specify expiration date in the future");

        require(
            !keys[id][to].exists || (keys[id][to].transferable == transferable && keys[id][to].expiration == expiration),
            "Another matching key already exists for the receiver, please revoke it before transfer"
            );
        
        if (key.uses > 0) {
            if (uses == key.uses) {
                delete keys[id][from];
            } else {
                keys[id][from].uses = keys[id][from].uses.sub(uses);
            }
        }

        if(keys[id][to].exists) {
            if (keys[id][to].uses != 0) {
                if (uses == 0) {
                    keys[id][to].uses = 0;
                } else {
                    keys[id][to].uses = keys[id][to].uses.add(uses);
                }
            }
        } else {
            keys[id][to].exists = true;
            keys[id][to].transferable = transferable;
            keys[id][to].expiration = expiration;
            keys[id][to].uses = uses;
        }

        emit Transfer(id, from, to, transferable, expiration, uses);
    }

    function isValidExpiration(uint expiration) public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return expiration == 0 || expiration >= now;
    }

    function isValidKey(bool exists, uint expiration) public view returns (bool) {
        return exists && isValidExpiration(expiration);
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
     
    modifier only(bool condition) {
        require(condition, "You don't have the permission required for this operation");
        _;
    }

    /**
     * @dev A function that unlock a function lock .
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
     * @notice the function tries each key in order until one matches, the key that matches will be used one time. if none match, a revert occurs.
     * @param id the id of the lock which the user want to unlock.
     */

    function unlock(bytes32 id) internal returns (bool) {
        bool used = false;
        Key memory key = keys[id][msg.sender];
        
        if (isValidKey(key.exists, key.expiration)) {
            if (key.uses == 1) {
                delete keys[id][msg.sender];
            } else if (key.uses > 1){
                keys[id][msg.sender].uses --;
            }
            emit Use(id, msg.sender);
            used = true;
        }
        return used;
    }

    function toBytes(uint256 x) public pure returns (bytes b) {
        b = new bytes(32);
        // solium-disable-next-line security/no-inline-assembly
        assembly { mstore(add(b, 32), x) }
    }
}