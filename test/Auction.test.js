const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());
const { abi, evm } = require('../compileX');

let accounts;
let Auction;

beforeEach(async () => {
    // Get a list of accounts
    accounts = await web3.eth.getAccounts();

    //Use one of those accounts to deploy the contract
    Auction = await new web3.eth.Contract(abi)
        .deploy({
            data: evm.bytecode.object,
        })
        .send({from: accounts[0], gas: '1000000'});
});

describe('Auction', () => {
    it('Deploy a contract', () => {
        assert.ok(Auction.options.address);
    });
});