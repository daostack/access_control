pragma solidity ^0.4.24;

/**
 * @title A dummy contract used for testing.
 */
contract Dummy {
    event Funced(uint _arg0, uint _arg1);

    function func(uint _arg0, uint _arg1) public returns(uint, uint) {
        emit Funced(_arg0, _arg1);
        return (_arg0, _arg1);
    }
}