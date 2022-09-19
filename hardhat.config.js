//hardhat.config.js

require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-solhint");
require('dotenv').config();

// Replace this private key with your Callisto account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
const CALLISTO_PRIVATE_KEY = process.env.CALLISTO_PRIVATE_KEY;
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 module.exports = {
    solidity: {
      version: "0.8.16",
      settings: {
        optimizer: {
          enabled: true,
          runs: 1000,
        },
      },
    },
    networks: {
      callisto_testnet: {
        url: `https://testnet-rpc.callisto.network`,
        accounts: [`${CALLISTO_PRIVATE_KEY}`]
      },
      callisto_mainnet: {
        url: `https://rpc.callisto.network/`,
        accounts: [`${CALLISTO_PRIVATE_KEY}`]
      },
      binance_mainnet: {
        url: `https://bsc-dataseed.binance.org/`,
        accounts: [`${CALLISTO_PRIVATE_KEY}`]
      },
  
      polygon_mainnet: {
        url: `https://polygon-rpc.com/`,
        accounts: [`${CALLISTO_PRIVATE_KEY}`]
      }
    }
  };
