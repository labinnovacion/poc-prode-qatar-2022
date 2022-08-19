const path = require('path');
const fs = require ('fs');
const solc = require('solc');

const AuctionPath = path.resolve(__dirname, 'contracts\\auction','auction.sol');
const source = fs.readFileSync(AuctionPath, 'utf8');
// console.log('AuctionPath:' + AuctionPath);
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

// console.log(JSON.stringify(Auction));

// console.log(solc.compile(JSON.stringify(Auction)));

// console.log(JSON.parse( solc.compile(JSON.stringify(Auction))).contracts[
//     'auction.sol'
// ].Auction);
module.exports =
JSON.parse( solc.compile(JSON.stringify(Auction))).contracts[
    'auction.sol'
].Auction;
