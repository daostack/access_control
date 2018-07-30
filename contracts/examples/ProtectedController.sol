pragma solidity ^0.4.21;

import "../Protected.sol";

/**
 * @title a simple example of how to use the Protected base class.
 */
contract ProtectedController is Protected {
    uint schemesRegistered = 0;
    mapping(uint => uint) public schemes;

    constructor() public {
        /*
            The sender has *2 days from now* to register *up to 10* schemes, he *can transfer* this capability to other accounts
        */
        lock("registerScheme");
        transferKeyFrom("registerScheme", this, msg.sender, true, now + 2 days, 10);

        /*
            Only the sender can reset the schemes at any time, only once.
        */
        lock("reset");
        transferKeyFrom("reset", this, msg.sender, false, 0, 1);
    }

    function registerScheme() only(["registerScheme"]) public {
        /*
            Once registered, *only* the original registerer can set the scheme params *once* *within 4 days*.
        */
        lock(keccak256("setParam", schemesRegistered));
        transferKeyFrom(keccak256("setParam", schemesRegistered), this, msg.sender, false, now + 4 days, 1);

        schemesRegistered++;
    }

    function setParam(uint scheme, uint param) only([keccak256("setParam", scheme)]) public {
        schemes[scheme] = param;
    }

    function reset() only([bytes32(this.reset.selector)]) public {
        for(uint i = 0; i < schemesRegistered; i++) {
            schemes[i] = 0;
        }
        schemesRegistered = 0;
    }
}