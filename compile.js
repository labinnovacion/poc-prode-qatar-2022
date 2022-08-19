const path = require('path');
const fs = require ('fs');
const solc = require('solc');

const AauctionLinkPath = path.resolve(__dirname, 'contracts','AuctionLink.sol');
const source = fs.readFileSync(AauctionLinkPath, 'utf8');

const AuctionLink = {
    language: 'Solidity',
    sources: {
        'AuctionLink.sol': {
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

// console.log(JSON.parse( solc.compile(JSON.stringify(AuctionLink))).contracts[
//     'AuctionLink.sol'
// ].AuctionLink);
module.exports =
JSON.parse( solc.compile(JSON.stringify(AuctionLink))).contracts[
    'AuctionLink.sol'
].AuctionLink;
