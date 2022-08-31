//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "hardhat/console.sol";

interface IAllowlist{
    function getUserStatus(address user) external view returns(bool status);
}

contract Auction {
    enum State {Started, Closed, Ended, Canceled }
    uint public constant FOUNDER = 1;
    uint public constant ADMIN = 2;
    uint public constant USER = 3;
    address public _allowlist;

    struct _Auction {
        State auctionState;
        address highestBidder;
        uint highestBid;
        uint step;
        string item;
        string imgUrl;       
    }
    _Auction[] public auctions;
    mapping (address => uint) public roles;
    

    constructor( address allowlist ){
        //Aqui hay que asignar el owner del contrato
        roles[msg.sender] = FOUNDER;
        _allowlist = allowlist;
        // console.log("Allowlist addr: ", _allowlist);
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
        require(IAllowlist(_allowlist).getUserStatus( msg.sender), 
            "Only Users can execute this");
        _;
    }

    function giveRole(address _holder, uint _newRole)  public onlyAdmins {
        // console.log("giveRole _holder: %s  _newRole:%d", _holder, _newRole);
        require( _newRole >= 0 && _newRole <= 3, "No tiene permisos para realizar esta accion");
        // console.log("giveRole PASS Require");
        if( _newRole == FOUNDER && roles[msg.sender] == FOUNDER){
            // console.log("No deberia estar pasando");
            roles[_holder] = _newRole;
            roles[msg.sender] = ADMIN;
        }
        else{
            // console.log("Araca");
            // console.log("roles(_holder): %d", roles[_holder]);

            if( roles[_holder] < ADMIN && _newRole < USER){
                // console.log("_handler: %s have rol: %d", _holder, _newRole);                
                roles[_holder] = _newRole;
            }
        }
    }

    function checkRole( address _holder, uint _role) public view returns(bool){
        bool result = false;
        if(roles[_holder] == _role ){
            result = true;
        }
        else {
            result = false;
        }
        return result;
    }
    //Auction Stuff

    function createAuction(string memory _item, string memory _imgUrl, uint _step) public onlyAdmins {
        console.log("item: %s", _item);
        console.log("imgUrl: %s", _imgUrl);
        console.log("step: %d", _step);
        _Auction memory initAuction = _Auction({
            auctionState: State.Started,
            highestBidder: msg.sender,
            highestBid: 0,
            step: _step,
            item: _item,
            imgUrl: _imgUrl
        });

        auctions.push(initAuction);
    }

    // function getAuctios() public view returns( _Auction[]  ){
    //     return auctions;
    // }

    function closeAuction(uint _auctionID) public onlyAdmins{

    }

    function reopenAuction(uint _auctionID) public onlyAdmins{

    }

    function cancelAuction(uint _auctionID) public onlyAdmins{

    }

    function bidAuction( uint _bid, uint _auctionID) public onlyUsers{
        
    }
}