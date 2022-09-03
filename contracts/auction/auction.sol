//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "../ERC20Token/IERC20Token.sol"; //Should be Cryptolink

interface IAllowlist{
    function getUserStatus(address user) external view returns(bool status);
}

contract Auction {
    enum State {Started, Closed, Ended, Canceled }
    uint8 public constant FOUNDER = 1;
    uint8 public constant ADMIN = 2;
    uint8 public constant USER = 3;
    address public _allowlist;

    address public erc20_contract = 0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //Cryptolink2 Address

    struct _Auction {
        State auctionState;
        address highestBidder;
        uint highestBid;
        uint step;
        string item;
        string imgUrl;       
    }
    _Auction[] public auctions;
    mapping (string => _Auction) mauctions;
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

    function setERC20Contract( address _erc20_contract ) public onlyAdmins {
        erc20_contract = _erc20_contract;
    }

    function giveRole(address _holder, uint _newRole)  public onlyAdmins {
        // console.log("giveRole _holder: %s  _newRole:%d", _holder, _newRole);
        require( _newRole >= 0 && _newRole < 3, "No tiene permisos para realizar esta accion");
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

    function setAdmin(address _newAdmin ) public onlyAdmins {
        roles[_newAdmin] = ADMIN;
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
        _Auction memory initAuction = _Auction({
            auctionState: State.Started,
            highestBidder: msg.sender,
            highestBid: 0,
            step: _step,
            item: _item,
            imgUrl: _imgUrl
        });

        mauctions[_item]=initAuction;
        auctions.push(initAuction);
    }

    function getAuctionsCount() public view returns( uint ){
        return auctions.length;
    }

    function getAuctions() public view returns( _Auction[] memory  ){
        _Auction[] memory auct = new _Auction[](auctions.length) ;
        for( uint i = 0; i < auctions.length; i++ ){
            _Auction storage auction = auctions[i];
            auct[i] = auction;
        }
        return auct;
    }

    function auctionState(uint _auctionID) public view returns(State){
        // uint auctionState = auctions[_auctionID].auctionState;
        // return auctionState;
        return auctions[_auctionID].auctionState;
    }

    function closeAuction(uint _auctionID) public onlyAdmins{
        _Auction storage _auction = auctions[_auctionID];
        
        require(_auction.auctionState == State.Started);
        _auction.auctionState = State.Closed;
    }

    function reopenAuction(uint _auctionID) public onlyAdmins{
        _Auction storage _auction = auctions[_auctionID];

        require(_auction.auctionState == State.Closed);
        _auction.auctionState = State.Started;
    }

    function cancelAuction(uint _auctionID) public onlyAdmins{
        _Auction storage _auction = auctions[_auctionID];

        // uint256 balance = erc20_contract.balance;
        //TODO: Hay que ver como se hace la devolucion de tokens al apostador
        // _auction.highestBidder.transfer(address(erc20_contract).balance);
        _auction.auctionState = State.Canceled;
    }

    function bidAuction( uint _bid, uint _auctionID) public onlyUsers{
        _Auction storage _auction = auctions[_auctionID];

        require(_auction.auctionState == State.Started, "La subasta se encuentra cerrada");
        require(msg.sender.balance >= _bid, "Fondos insuficientes");
        require(_bid >= _auction.highestBid + _auction.step, "La puja debe ser mas alta");

        //Verifica que no es la primer oferta
        if( _auction.highestBid > 0){
            // Se le devuelven los tokens al postor anterior
            
            //TODO: Ver como devolver los Tokens... asi evidentemente NO
            // _auction.highestBidder.transfer(_auction.highestBid);
            ICryptoLink(erc20_contract).transferFrom(address(this), _auction.highestBidder, _bid);
        }

        //TODO:Hay que hacer algo para que los tokens del jugador se carguen en el Balance del contrato?
        ICryptoLink(erc20_contract).transferFrom(msg.sender, address(this), _bid);
        // Actualizo los datos del nuevo jugador
        _auction.highestBid = _bid;
        _auction.highestBidder = msg.sender;
    }

    function rescueERC20( address _token, uint256 _amount) public onlyFounder {
        ICryptoLink(_token).transferFrom(address(this), msg.sender, _amount);
    }
}