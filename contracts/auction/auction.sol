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

    constructor(){
        //Aqui hay que asignar el owner del contrato
    }
}