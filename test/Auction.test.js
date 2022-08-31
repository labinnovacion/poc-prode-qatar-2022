const { expect } = require("chai");
const { ethers } = require("hardhat");
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

    it('Create an Auction', async () => {
        const [owner] = await ethers.getSigners();

        await auction.createAuction("Baffle","http://elserver//baffle.jpg", 10);

        console.log("I want to see the auctions");
        console.log(auction.auctions);
        const aa = auction.auctions[0];

        expect(aa.item).to.equal("Baffle");
    });
});