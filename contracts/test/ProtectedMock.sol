pragma solidity ^0.4.24;

import "../Protected.sol";


contract ProtectedMock is Protected {
    function revokeOwnerKey_(bytes32 _id, address _owner) public {
        return revokeOwnerKey(_id, _owner);
    }

    function grantKey_(
        bytes32 _id,
        address _to,
        bool _assignable,
        uint80 _startTime,
        uint80 _expiration,
        uint80 _uses
    ) public
    {
        return grantKey(
            _id,
            _to,
            _assignable,
            _startTime,
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
}