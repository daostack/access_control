pragma solidity ^0.4.24;

import "../lib/SafeMath80.sol";


/**
 * @title Protected
 * @dev base class that gives contracts a sophisticated access control mechanism
 */
contract Protected {
    using SafeMath80 for uint80;

    // Random placeholder for irrelevent params in lock _id. e.g. `unlock(keccak256(abi.encodePacked("method", param1, ANYTHING, param2)))`
    uint internal constant ANYTHING = uint(keccak256("ANYTHING"));

    struct Key {
        bool exists;
        bool assignable;
        uint80 startTime; // zero = effective immediately
        uint80 expiration; // zero = no expiration
        uint80 uses; // zero = infinite uses
    }

    //      id                 owner      key
    mapping(bytes32 => mapping(address => Key)) public keys;

    event AssignKey(
        bytes32 indexed _id,
        address indexed _from, // zero = granted by contract
        address indexed _to,
        bool _assignable,
        uint80 _startTime,
        uint80 _expiration,
        uint80 _uses
    );
    event RevokeKey(
        bytes32 indexed _id,
        address indexed _owner
    );

    /**
     * @dev does the owner have a valid key for the lock id
     * @param _id lock id
     * @param _owner owner address
     */
    function unlockable(bytes32 _id, address _owner) public view returns (bool) {
        Key memory key = keys[_id][_owner];
        return key.exists && isValidExpiration(key.expiration) && key.startTime <= now;
    }

    /**
     * @dev transfer partial or all capabilities from the sender to an account
     * @param _id lock id
     * @param _to recipient
     * @param _assignable can the recipient further assignKey capabilities to other accounts?
     * @param _expiration the key's expiration time (block timestamp)
     * @param _uses number of times this key can be used (in `unlock(..)`)
     */
    function assignKey(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint80 _startTime,
        uint80 _expiration,
        uint80 _uses
    ) public
    {
        Key memory key = keys[_id][msg.sender];
        require(key.exists && isValidExpiration(key.expiration), "Invalid key");
        require(key.assignable, "Key is not assignable");
        require(key.startTime <= now || _startTime >= key.startTime, "Cannot reduce key's future start time");
        require(key.expiration == 0 || (_expiration <= key.expiration && _expiration > 0), "Cannot extend key's expiration");
        require(_expiration == 0 || _startTime < _expiration, "Start time must be strictly less than expiration");
        require(isValidExpiration(_expiration), "Expiration must be in the future");
        require(key.uses == 0 || (_uses <= key.uses && _uses > 0), "Not enough uses avaiable");

        bool possesKey = unlockable(_id, _to) || keys[_id][_to].startTime > now;
        require(
            !possesKey || (
                keys[_id][_to].assignable == _assignable && keys[_id][_to].expiration == _expiration && (
                    // both in the past or are exactly equal
                    (keys[_id][_to].startTime <= now && _startTime <= now) ||
                    keys[_id][_to].startTime == _startTime
                )
            ),
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
            keys[_id][_to] = Key(true, _assignable, _startTime, _expiration, _uses);
        }

        emit AssignKey(
            _id,
            msg.sender,
            _to,
            _assignable,
            _startTime,
            _expiration,
            _uses
        );
    }

    /**
     * @dev transfer all capabilities from the sender to an account
     * @param _id lock id
     * @param _to recipient
     */
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
            key.startTime,
            key.expiration,
            key.uses
        );
    }

    /**
     * @dev revoke the sender's key
     * @param _id lock id
     */
    function revokeKey(bytes32 _id) public {
        revokeOwnerKey(_id, msg.sender);
    }

    /**
     * @dev is the current block timestamp less than `_expiration`
     * @param _expiration block timestamp
     */
    function isValidExpiration(uint80 _expiration) internal view returns (bool valid) {
        return _expiration == 0 || _expiration >= now;
    }

    /**
     * @dev Revokes an account's key
     * @param _id lock id
     * @param _owner the account address
     */
    function revokeOwnerKey(bytes32 _id, address _owner) internal {
        delete keys[_id][_owner];
        emit RevokeKey(_id, _owner);
    }

    /**
     * @dev Grant capabilities to account (overwrites existing key)
     * @param _id lock id
     * @param _to recipient
     * @param _assignable can the recipient further assignKey his capabilities to other accounts?
     * @param _expiration the key's expiration time (block timestamp)
     * @param _uses number of times this key can be used (in `unlock(..)`)
     */
    function grantKey(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint80 _startTime,
        uint80 _expiration,
        uint80 _uses
    ) internal
    {
        require(_expiration == 0 || _startTime < _expiration, "Start time must be strictly less than expiration");
        require(isValidExpiration(_expiration), "Expiration must be in the future");

        keys[_id][_to].exists = true;
        keys[_id][_to].assignable = _assignable;
        keys[_id][_to].startTime = _startTime;
        keys[_id][_to].expiration = _expiration;
        keys[_id][_to].uses = _uses;

        emit AssignKey(
            _id,
            0,
            _to,
            _assignable,
            _startTime,
            _expiration,
            _uses
        );
    }

    /**
     * @dev Grant full capabilities to account (assignable, no expiration, infinite uses)
     * @param _id lock id
     * @param _to recipient
     */
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

    /**
     * @dev A convenience modifier that guarantees a condition to be true. eg. `guarantee(unlock('Admin') || unlock('Worker'))`
     * @param _condition the condition to be met
     */
    modifier guarantee(bool _condition) {
        require(_condition, "Insufficiant permissions");
        _;
    }

    /**
     * @dev unlock a lock if sender has a valid key.
     * @param _id lock id
     */
    function unlock(bytes32 _id) internal returns (bool) {
        if (unlockable(_id, msg.sender)) {
            subtractUses(_id, 1);
            return true;
        }
        return false;
    }

    function subtractUses(bytes32 _id, uint80 _uses) private {
        Key memory key = keys[_id][msg.sender];
        if (key.uses > 0) {
            if (key.uses == _uses) {
                delete keys[_id][msg.sender];
            } else {
                keys[_id][msg.sender].uses = keys[_id][msg.sender].uses.sub(_uses);
            }
        }
    }
}
