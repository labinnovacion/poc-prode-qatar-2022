const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());
const { abi, evm } = require('../compile');

let accounts;
let AuctionLink;

beforeEach(async () => {
    // Get a list of accounts
    accounts = await web3.eth.getAccounts();

    //Use one of those accounts to deploy the contract
    AuctionLink = await new web3.eth.Contract(abi)
        .deploy({
            data: evm.bytecode.object,
        })
        .send({from: accounts[0], gas: '1000000'});
});

describe('AuctionLink', () => {
    it('Deploy a contract', () => {
        assert.ok(AuctionLink.options.address);
    });

    it('add one user to auctions', async () =>{
        await AuctionLink.methods.giveRole(accounts[1], AuctionLink.USER).call({
            from: accounts[0]
        });

        const exists = await AuctionLink.methods.holderExists(accounts[1]).call({
            from: accounts[0]
        });

        console.log('Exists:', exists);
        assert.ok(exists);
    });
});