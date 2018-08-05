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
    mapping(bytes32 => mapping(address => Key[])) public keys;

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
     */
    function lock(
        bytes32 id
    ) internal {        
        if (keys[id][this].length == 0){
            keys[id][this].length++;
            keys[id][this][0].exists = true;
            keys[id][this][0].transferable = true;

            emit Lock(id);
        }
    }

    /**
     * @dev Destroy a given key making it non existent.
     * @param id lock id,
     * @param owner the owner of the key.
     */
    function revokeFrom(bytes32 id, address owner, uint i) internal {
        keys[id][owner][i].exists = false;
        emit Revoke(id, owner);
    }

    /**
     * @dev Destroy the sender's key.
     * @param id lock id,
     */
    function revoke(bytes32 id, uint i) public {
        revokeFrom(id, msg.sender, i);
    }

    /**
     * @dev Destroy the sender's key.
     * @param id lock id,
     */
    function revokeAllFrom(bytes32 id, address owner) internal {
        for(uint i = 0; i < keys[id][owner].length; i++) {
            revokeFrom(id, owner, i);
        }
    }

    /**
     * @dev Destroy the sender's key.
     * @param id lock id,
     */
    function revokeAll(bytes32 id) public {
        revokeAllFrom(id, msg.sender);
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
        uint i,
        address from,
        address to,
        bool transferable,
        uint expiration,
        uint uses
    ) internal {
        Key memory key = keys[id][from][i];
        require(key.exists);
        require(key.transferable);
        require(expiration != 0 || key.expiration == 0);
        require(expiration <= key.expiration || key.expiration == 0);
        require(uses != 0 || key.uses == 0);
        require(uses <= key.uses || key.uses == 0);

        if (uses > 0 && uses == key.uses) {
            keys[id][from][i].exists = false;
        } else if (key.uses > 0) {
            keys[id][from][i].uses = keys[id][from][i].uses.sub(uses);
        }

        bool merged = false;

        if (keys[id][to].length > 0) {
            for(uint k = 0; k < keys[id][to].length; k++) {
                if (keys[id][to][k].exists && keys[id][to][k].transferable == transferable && keys[id][to][k].expiration == expiration) {
                    merged = true;
                    if (keys[id][to][k].uses > 0) {
                        keys[id][to][k].uses = keys[id][to][k].uses.add(uses);
                    }
                    break;
                }
            }
        }

        if(!merged) {
            Key memory newKey = Key(true, transferable, expiration, uses);
            keys[id][to].push(newKey);
        }

        emit Transfer(id, from, to, transferable, expiration, uses);
    }

    function transferKeyFrom(
        bytes32 id,
        address from,
        address to,
        bool transferable,
        uint expiration,
        uint uses
    ) internal {
        transferKeyFrom(id, 0, from, to, transferable, expiration, uses);
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
        uint i,
        address to,
        bool transferable,
        uint expiration,
        uint uses
    ) public {
        transferKeyFrom(
            id,
            i,
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
        for(uint i = 0 ; i < keys[id][from].length; i++) {
            Key memory key = keys[id][from][i];
            transferKeyFrom(id, i, from, to, true, key.expiration, key.uses);
        }
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

    function unlock(bytes32 id, uint keyPos) internal returns (bool) {
        Key memory key = keys[id][msg.sender][keyPos];
        if (
            key.exists &&
            (key.expiration == 0 || key.expiration >= now)
        ) {
            if (key.uses == 1) {
                keys[id][msg.sender][keyPos].exists = false;
            } else if (key.uses > 1){
                keys[id][msg.sender][keyPos].uses --;
            }
            emit Use(id, msg.sender);
            return true;
        }
        return false;
    }

    function unlock(bytes32 id) internal returns (bool) {
        // @notice the loop is intended to prevent a case where the operation faied
        // because one of the key was expired
        for (uint i = 0; i < keys[id][msg.sender].length; i++) {
            if (unlock(id, i)) {
                return true;
            }
        }

        return false;
    }

    function toBytes(uint256 x) public pure returns (bytes b) {
        b = new bytes(32);
        // solium-disable-next-line security/no-inline-assembly
        assembly { mstore(add(b, 32), x) }
    }
}