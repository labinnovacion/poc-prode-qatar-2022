const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { assertHardhatInvariant } = require("hardhat/internal/core/errors");
const { boolean } = require("hardhat/internal/core/params/argumentTypes");

let _Allowlist;
let _Auction;
let allowlist;
let auction;
beforeEach(async () => {
    _Allowlist = await ethers.getContractFactory("Allowlist");
    _Auction = await ethers.getContractFactory("Auction");
    allowlist = await _Allowlist.deploy();
    auction = await _Auction.deploy(allowlist.address);
});

describe('Auction', () => {
    it('Deploy a contract', async () => {
        expect(auction.address).is.not.NaN;
        expect(allowlist.address).is.not.NaN;
    });
    
    it('Create one Admin', async () => {
        const [owner, admin1] = await ethers.getSigners();

        // await Auction.giveRole(admin1.address, Auction.ADMIN);
        await auction.giveRole(admin1.address, 2);

        const isAdmin = await auction.checkRole(admin1.address, 2);
        expect(isAdmin).is.true;
        // expect(true).is.true;
    });

    it('add player to allowlist', async () => {
        const [owner, player1, player2] = await ethers.getSigners();

        await allowlist.setUserStatus(player1.address, true);
        await allowlist.setUserStatus(player2.address, false);

        try{
            const player1Status = await allowlist.getUserStatus(player1.address);
            const player2Status = await allowlist.getUserStatus(player2.address);

            // console.log("Player " + player1.address + " Status:" + player1Status);
            expect(player1Status).is.true;
            // console.log("Player " + player2.address + " Status:" + player2Status);
            expect(player2Status).is.false;
        }
        catch(error){
            assert(false,error);
        }

    });

    it('Create an Auction', async () => {
        const [owner] = await ethers.getSigners();

        await auction.createAuction("Baffle","http://elserver//baffle.jpg", 10);

        const count = await auction.getAuctionsCount();
        const auctions = await auction.getAuctions();

        expect(count).to.equal(1);
        expect(auctions[0].item).to.equals("Baffle");
    });

    it('Create two Auctions', async () => {
        const [owner] = await ethers.getSigners();

        await auction.createAuction("Baffle","http://elserver//baffle.jpg", 10);
        await auction.createAuction("Amplificador","http://elserver//amplificador.jpg", 10);

        const count = await auction.getAuctionsCount();
        const auctions = await auction.getAuctions();

        expect(count).to.equal(2);
        expect(auctions[0].item).to.equals("Baffle");
        expect(auctions[1].item).to.equals("Amplificador");
    });

    it('Admin try to Bid Auction', async () => {
        const [owner] = await ethers.getSigners();

        await auction.createAuction("Baffle","http://elserver//baffle.jpg", 10);

        try{
            await auction.bidAuction(20, 0);
            assert(false);
            
        } catch(error) {
            assert(true, error);
        }
    });

    it('Player try to create an Auction', async() => {
        const [owner, admin, player1] = await ethers.getSigners();

        await allowlist.setUserStatus(player1.address, true);

        try {
            await   auction.connect(player1).createAuction({
                '_item': 'Delorean',
                '_imgurl': 'https://elserver//delorean.jpg', 
                '_step': 10
            });
            assert(false,"Some Error");
        }
        catch(error){
            // console.log(error);
            assert(true, error);
        }
    });

});