pragma solidity ^0.4.24;

import "./ERC1480.sol";


/// @title ERC1480Storage - Access Control, RECOMMENDED data structure
contract ERC1480Storage is ERC1480 {
    mapping(bytes32 => mapping(address => Key)) public keys;
}
