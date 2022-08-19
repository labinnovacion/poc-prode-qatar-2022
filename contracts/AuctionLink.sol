//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionLink {
    enum State {Started, Closed, Ended, Canceled }
    uint public constant FOUNDER = 1;
    uint public constant ADMIN = 2;
    uint public constant USER = 3;

    struct TokenHolder {
        uint _balance;
        uint _role;
    }

    struct Auction {
        State auctionState;
        address highestBidder;
        uint highestBid;
        uint step;
        string item;
        string imgUrl;       
    }

    Auction[] public auctions;

    mapping (address => TokenHolder) tokenHolders;

    // mapping (address => uint) allowed;

    constructor (){
        tokenHolders[msg.sender]._role = FOUNDER;
    }

    modifier onlyFounder(){
        require(tokenHolders[msg.sender]._role == FOUNDER, "Only Founder can execute this");
        _;
    }

    modifier onlyAdmins(){
        require(tokenHolders[msg.sender]._role == ADMIN || tokenHolders[msg.sender]._role == FOUNDER, "Only Founder or Admins can execute this");
        _;
    }

    modifier onlyPlayers() {
        require (tokenHolders[msg.sender]._role == USER, "Only Users can execute this");
        _;
    }

    function giveRole(address _tokenHolder, uint _newRole)  public onlyAdmins {
        event LogSomething( string msg);

        require( _newRole >= 0 && _newRole <= 3, "No tiene permisos para realizar esta accion");
        if( _newRole == FOUNDER && tokenHolders[msg.sender]._role==FOUNDER){
            tokenHolders[_tokenHolder]._role = _newRole;
            tokenHolders[msg.sender]._role = ADMIN;

            emit LogSomething("now Founder");
        }
        else{
            if( tokenHolders[_tokenHolder]._role < ADMIN && _newRole < FOUNDER){
                tokenHolders[_tokenHolder]._role = _newRole;

                emit LogSomething("now User");
            }
        }
    }

    function holderExists(address _tokenHolder) public view onlyAdmins returns(bool){
        if(tokenHolders[_tokenHolder]._role != 0 ){
            return true;
        }

        return false;
    }
        // State auctionState;
        // address highestBidder;
        // uint highestBid;
        // uint step;
        // string item;
        // string imgUrl;       
    // function createAuction( string memory _item, string memory _imgUrl, uint _step) public onlyAdmins{
    //     Auction memory initAuction;
    //     initAuction = Auction({
    //         auctionState: State.Started,
    //         highestBidder: msg.sender,
    //         highestBid: 0,
    //         step: _step,
    //         item: _item,
    //         imgUrl, _imgUrl             
    //     });

    //     auctions.push(initAuction); 
    // }
}
