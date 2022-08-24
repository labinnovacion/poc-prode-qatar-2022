const path = require('path');
const fs = require ('fs-extra');
const solc = require('solc');

const AuctionPath = path.resolve(__dirname, '..\\..\\contracts\\auction','auction.sol');
const source = fs.readFileSync(AuctionPath, 'utf-8');

// console.log(__dirname);

const Auction = {
    language: 'Solidity',
    sources: {
        'auction.sol': {
            content: source,
        },
    },
    settings: {
        outputSelection: {
            '*': {
                '*': ['*'],
            },
        },
    },
};

// console.log(source);

// console.log(JSON.stringify(Auction));

//console.log(solc.compile(JSON.stringify(Auction)));

// console.log(JSON.parse( solc.compile(JSON.stringify(Auction))).contracts[
//     'auction.sol'
// ].Auction);
module.exports =
JSON.parse( solc.compile(JSON.stringify(Auction))).contracts[
    'auction.sol'
].Auction;

