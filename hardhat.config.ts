require("dotenv").config();

import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";
import "solidity-coverage";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: process.env.FORKING_URL,
        blockNumber: 12126175,
      },
      gas: 8000000,
      blockNumber: 12126175,
      blockGasLimit: 8000000,
      gasPrice: 0,
      timeout: 100000,
    },
    development: {
      url: "http://localhost:8545",
      gas: 8000000,
      blockGasLimit: 8000000,
      gasPrice: 0,
    },
  },

  solidity: {
    version: "0.7.3",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },

  gasReporter: {
    currency: "USD",
    gasPrice: 100,
    enabled: true,
    coinmarketcap: process.env.COIN_MARKET_CAP,
  },
};
