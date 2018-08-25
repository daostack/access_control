pragma solidity ^0.4.24;


contract Group {
    function isMember(address _account) public view returns(bool);

    modifier onlyMember() {
        require(isMember(msg.sender), "Not a member of this group");

        _;
    }

    function forward(address _to, bytes4 _selector, bytes _args) public payable onlyMember {
        /// TODO: Figure out how to best forward the call
    }
}


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


contract InverseGroup is Group {
    Group group;

    constructor(Group _group) public {
        group = _group;
    }

    function isMember(address _account) public view returns(bool) {
        return !group.isMember(_account);
    }
}