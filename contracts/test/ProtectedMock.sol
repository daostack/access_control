pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../Protected.sol";


contract ProtectedMock is AccessControl {

    bytes32[][] noLocks;

    function revokeOwnerKey_(bytes32 _id, address _owner) public {
        return revokeOwnerKey(_id, _owner);
    }

    function grantKey_(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint _expiration,
        uint _uses
    ) public
    {
        return grantKey(
            _id,
            _to,
            _assignable,
            _expiration,
            _uses
        );
    }

    function grantFullKey_(bytes32 _id, address _to) public {
        return grantFullKey(_id, _to);
    }

    function unlock_(bytes32 _id) public returns (bool) {
        return unlock(_id);
    }

    function getLocksForFunction(bytes4 _functionId) external view returns (bytes32[][] lockSets) {
        lockSets = noLocks; // No locked methods, returns an empty data set
    }
}
