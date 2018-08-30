pragma solidity ^0.4.24;


/**
 * @title Abstract base contract for all groups.
 */
contract Group {

    /**
     * @dev Check if an account belongs to this group.
     * @param _account the account to check.
     */
    function isMember(address _account) public view returns(bool);

    /**
     * @dev Modifier for restricting access to members of the group.
     */
    modifier onlyMember() {
        require(isMember(msg.sender), "Not a member of this group");

        _;
    }

    /**
     * @dev Call a method on a contract in the name of the group.
     * @param _to contract address to call.
     * @param _selector function selector.
     * @param _args any arguments to the function.
     */
    function forward(address _to, bytes4 _selector, bytes _args) public payable onlyMember {
        /// TODO: Figure out how to best forward the call
    }
}

/**
 * @title Group with fixed members set at creation time.
 */
contract FixedGroup is Group {
    mapping(address => bool) members;

    constructor(address[] _members) public {
        for (uint i = 0; i < _members.length; i++) {
            members[_members[i]] = true;
        }
    }

    function isMember(address _account) public view returns(bool) {
        return members[_account];
    }
}

/**
 * @title Group that comprises of all members belonging to at least one subgroup.
 */
contract UnionGroup is Group {
    Group[] subgroups;

    constructor(Group[] _subgroups) public {
        subgroups = _subgroups;
    }

    function isMember(address _account) public view returns(bool) {
        for (uint i = 0; i < subgroups.length; i++) {
            if (subgroups[i].isMember(_account)) {
                return true;
            }
        }
        return false;
    }
}

/**
 * @title Group that comprises of all members belonging to all subgroups.
 */
contract IntersectionGroup is Group {
    Group[] subgroups;

    constructor(Group[] _subgroups) public {
        subgroups = _subgroups;
    }

    function isMember(address _account) public view returns(bool) {
        for (uint i = 0; i < subgroups.length; i++) {
            if (!subgroups[i].isMember(_account)) {
                return false;
            }
        }
        return true;
    }
}

/**
 * @title Group that comprises of all members not belonging to a group.
 */
contract InverseGroup is Group {
    Group group;

    constructor(Group _group) public {
        group = _group;
    }

    function isMember(address _account) public view returns(bool) {
        return !group.isMember(_account);
    }
}
