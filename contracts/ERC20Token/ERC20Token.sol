// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ERC20Token
 * @dev This contract manages the ERC20 token for the game.
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Allowlist/IAllowlist.sol";

/// @custom:security-contact araujo_matias@redlink.com.ar
contract CryptoLink is ERC20, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CONTRACT_MINTER_ROLE =
        keccak256("CONTRACT_MINTER_ROLE");
    address public allowlist_contract =
        0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //AllowList contract

    event AllowlistContractSet(
        address indexed newContract,
        address indexed oldContract
    );

    constructor() ERC20("CryptoLink", "CRL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setAllowlistContract(address _allowlist_contract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit AllowlistContractSet(_allowlist_contract, allowlist_contract);
        allowlist_contract = _allowlist_contract;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused checkForPlayer {
        super._beforeTokenTransfer(from, to, amount);
    }

    modifier checkForPlayer() {
        require(
            IAllowlist(allowlist_contract).getUserStatus(_msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(MINTER_ROLE, _msgSender()),
            "No autorizado."
        );
        _;
    }
}
