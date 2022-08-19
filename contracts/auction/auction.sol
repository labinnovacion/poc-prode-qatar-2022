//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Auction {
    enum State {Started, Closed, Ended, Canceled }
    uint public constant FOUNDER = 1;
    uint public constant ADMIN = 2;
    uint public constant USER = 3;


    struct _Auction {
        State auctionState;
        address highestBidder;
        uint highestBid;
        uint step;
        string item;
        string imgUrl;       
    }
    _Auction[] public auctions;
    mapping (address => uint) roles;
    constructor(){
        //Aqui hay que asignar el owner del contrato
        roles[msg.sender] = FOUNDER;
    }

    modifier onlyFounder(){
        require(roles[msg.sender] == FOUNDER, "Only Founder can execute this");
        _; 
    }

    modifier onlyAdmins(){
        require(roles[msg.sender] == FOUNDER || roles[msg.sender] == ADMIN, 
            "Only Founders or Admins can execute this");
        _;
    }

    modifier onlyUsers(){
        require(roles[msg.sender] == USER, 
            "Only Users can execute this");
        _;
    }

    function giveRole(address _holder, uint _newRole)  public onlyAdmins {
        require( _newRole >= 0 && _newRole <= 3, "No tiene permisos para realizar esta accion");
        if( _newRole == FOUNDER && roles[msg.sender] == FOUNDER){
            roles[_holder] = _newRole;
            roles[msg.sender] = ADMIN;
        }
        else{
            if( roles[_holder] < ADMIN && _newRole < FOUNDER){
                roles[_holder] = _newRole;
            }
        }
    }
}