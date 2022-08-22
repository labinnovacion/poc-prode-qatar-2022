// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Allowlist is Ownable {

    mapping( address => bool) users;

    function setUserStatus(address user, bool status) public onlyOwner {
        users[user] = status;
    }

    function getUserStatus(address user) public view returns(bool status){
        return users[user];
    }
}