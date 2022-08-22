//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
import "@openzeppelin/contracts@4.7.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./DataTypesDeclaration.sol";

contract PRODE is Pausable, AccessControl {


    /***    Roles   ***/
    //El Admin 8-)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    //Tiene permisos para pausar TODO
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //Tiene permisos para modificar partidos
    bytes32 public constant MATCH_ROLE = keccak256("MATCH_ROLE");
    
    //Son los que pueden jugar
    bytes32 public constant PLAYER_ROLE = keccak256("PLAYER_ROLE");


    /***    Constantes  ***/
    address public erc20_contract = 0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //Cryptolink2 Address

    /***    Mapa de ID -> Partido    ***/
    mapping(string => Match) public matches;

    /*** Datos del user -> match -> bet 
    La idea es que se p***/
    mapping( address , mapping(string,Bet) ) public gameData;

    /*Eventos*/
    event ProdeContractSet(address indexed newContract, address indexed oldContract);


    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MATCH_ROLE, msg.sender);
    }

    function setERC20Contract(address _erc20_contract) public onlyRole(ADMIN_ROLE)
    {
        emit ProdeContractSet(_erc20_contract, erc20_contract);
        erc20_contract = _erc20_contract;
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /***    Funciones del PRODE    ***/
    /**
     * @dev 
     * @param num value to store
     */
    function bet(string matchId, uint result, uint goalA ,uint goalB) public returns(uint status){

    }

    function clearBet(string matchId) public returns(uint status){

    }

    function claimPrize(string matchId) public returns(uint status){
        //Si es necesario mintearle tokens al usuario...
        //Acá podría 
        ERC20Interface(erc20_contract).mint(_msgSender(), _erc20_amount);
    }

    function createMatch(string matchId) public onlyRole(MATCH_ROLE) returns(Match match_data){

    }
    function updateMatch(string matchId) public onlyRole(MATCH_ROLE) returns(Match match_data){

    }
    function deleteMatch(string matchId) public onlyRole(MATCH_ROLE) returns(bool success){

    }
    function getMatch(string matchId) public onlyRole(MATCH_ROLE) returns(Match match_data){

    }

}