// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/**
 * @title ICryptoLink
 * @dev This interface manages the Allowlist of the game
 */

interface IAllowlist {
    function setUserStatus(address user, bool status) external;

    function getUserStatus(address user) external view returns (bool status);
}
