const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

let _Allowlist;
let _Auction;
let _CryptoLink;
let allowlist;
let auction;
let cryptolink;

beforeEach(async () => {
    _Allowlist = await ethers.getContractFactory("Allowlist");
    _Auction = await ethers.getContractFactory("Auction");
    _CryptoLink = await ethers.getContractFactory("CryptoLink");
    allowlist = await _Allowlist.deploy();
    auction = await _Auction.deploy(allowlist.address);
    cryptolink = await _CryptoLink.deploy();
    auction.setERC20Contract(cryptolink.address);
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
        const [owner, player1] = await ethers.getSigners();

        await allowlist.setUserStatus(player1.address, true);

        try {
            await   auction.connect(player1).createAuction(
                'Delorean',
                'https://elserver//delorean.jpg', 
                10
            );
            assert.fail;
        }
        catch(error){
            assert.ok;
        }
    });

    it('Admin close an Auction', async() => {
        const [owner, admin1, admin2] = await ethers.getSigners();

        await auction.setAdmin(admin1.address);
        await auction.setAdmin(admin2.address);

        const auctionId = 0;
        await auction.connect(admin1).createAuction(
            'Delorean',
            'https://elserver//delorean.jpg', 
            10
        );
        try{
            await auction.connect(admin2).closeAuction(auctionId);
            assert.ok;
        }
        catch( error){
            assert.fail;
        }
    });

    it('Player try to close an Auction', async() => {
        const [owner, admin1, player] = await ethers.getSigners();

        await auction.setAdmin(admin1.address);
        await allowlist.setUserStatus(player.address, true);

        const auctionId = 0;
        await auction.connect(admin1).createAuction(
            'Delorean',
            'https://elserver//delorean.jpg', 
            10
        );
        try{
            await auction.connect(player).closeAuction(auctionId);
            assert.fail;
        }
        catch( error){
            assert.ok;
        }
    });

    it('Admin try to close closed Auction', async() => {
        const [owner, admin1, admin2] = await ethers.getSigners();

        await auction.setAdmin(admin1.address);
        await auction.setAdmin(admin2.address);

        const auctionId = 0;
        await auction.connect(admin1).createAuction(
            'Delorean',
            'https://elserver//delorean.jpg', 
            10
        );
        await auction.connect(admin1).closeAuction(auctionId);
        try{
            await auction.connect(admin2).closeAuction(auctionId);
            assert.fail;
        }
        catch( error){
            assert.ok;
        }
    });

    it('Admin reopen an Auction', async() => {
        const [owner, admin1, admin2] = await ethers.getSigners();

        await auction.setAdmin(admin1.address);
        await auction.setAdmin(admin2.address);

        const auctionId = 0;
        await auction.connect(admin1).createAuction(
            'Delorean',
            'https://elserver//delorean.jpg', 
            10
        );
        await auction.connect(admin1).closeAuction(auctionId);
        try{
            await auction.connect(admin2).reopenAuction(auctionId);
            assert.ok;
        }
        catch( error){
            assert.fail;
        }
    });

    it('Admin try to reopen an unclosed Auction', async() => {
        const [owner, admin1, admin2] = await ethers.getSigners();

        await auction.setAdmin(admin1.address);
        await auction.setAdmin(admin2.address);

        const auctionId = 0;
        await auction.connect(admin1).createAuction(
            'Delorean',
            'https://elserver//delorean.jpg', 
            10
        );

        try{
            await auction.connect(admin2).reopenAuction(auctionId);
            assert.fail;
        }
        catch( error){
            assert.ok;
        }
    });

    it('bid an Auction', async() => {
        const [owner, admin1, player] = await ethers.getSigners();

        await auction.setAdmin(admin1.address);
        await allowlist.setUserStatus(player.address, true);
        await cryptolink.mint(player.address, 1000);
        await cryptolink.approve(player.address, 100000000000);
        const auctionId = 0;
        await auction.connect(admin1).createAuction(
            'Delorean',
            'https://elserver//delorean.jpg', 
            10
        );

        try{
            const playerPreBalance = await cryptolink.balanceOf(player.address);
            console.log("Balance Pre:" + playerPreBalance);
            await auction.connect(player).bidAuction(20, auctionId);
            const playerPosBalance = await cryptolink.balanceOf(player.address);
            console.log("Balance Pos:" + playerPosBalance);
            
            assert.fail;
        }
        catch( error){
            console.log(error);
            assert.ok;
        }
    });

});