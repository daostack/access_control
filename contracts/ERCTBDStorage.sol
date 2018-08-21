pragma solidity ^0.4.24;

import "./ERCTBD.sol";


/// @title ERCTBDStorage - Access Control, RECOMMENDED data structure
contract ERCTBDStorage is ERCTBD {
    mapping(bytes32 => mapping(address => Key)) public keys;
}
