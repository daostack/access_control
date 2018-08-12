pragma solidity ^0.4.24;

import "./Protected.sol";

/**
 * @title a simple example of how to use the Protected base class.
 */
contract ProtectedController is Protected {
    uint public schemesRegistered = 0;
    mapping(uint => uint) public schemes;

    constructor() public {
        /*
            The sender has *2 days from now* to register *up to 10* schemes, he *can transfer* this capability to other accounts
        */
        
        // solium-disable-next-line security/no-block-members
        setKey("registerScheme", msg.sender, true, now + 2 days, 10);

        /*
            Only the sender can reset the schemes at any time, only once.
        */
        setKey("reset", msg.sender, false, 0, 1);
    }

    function registerScheme() public only(unlock("registerScheme")) {
        /*
            Once registered, *only* the original registerer can set the scheme params *once* *within 4 days*.
        */

        // solium-disable-next-line security/no-block-members
        setKey(keccak256("setParam", schemesRegistered), msg.sender, false, now + 4 days, 1);

        schemesRegistered++;
    }

    function setParam(uint scheme, uint param) public only(unlock(keccak256("setParam", scheme))) {
        schemes[scheme] = param;
    }

    function reset() public only(unlock("reset")) {
        for(uint i = 0; i < schemesRegistered; i++) {
            schemes[i] = 0;
        }
        schemesRegistered = 0;
    }

    
}