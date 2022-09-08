// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ICryptoLink
 * @dev This interface manages the ERC20 token for the game.
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

interface ICryptoLink {
    function mint(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}
