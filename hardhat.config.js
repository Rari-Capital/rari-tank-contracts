require("@tenderly/hardhat-tenderly");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require("hardhat-gas-reporter");

require("dotenv").config()

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY,
        blockNumber: 11911184,
      },
      gas: 8000000,
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
  compilers: [{ version: "0.7.3" }, { version: "0.6.6" }],
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },

  tenderly: {
    username: "JetDeveloping",
    project: "tanks"
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 100,
    enabled: true,
    coinmarketcap: process.env.COIN_MARKET_CAP
  }
};