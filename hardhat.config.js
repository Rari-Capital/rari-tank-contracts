require("@nomiclabs/hardhat-ganache");
require("@tenderly/hardhat-tenderly");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require("solidity-coverage");

const removeConsoleLog = require("hardhat-preprocessor");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/UPMBuJ4TAQrsy9sdb4QSKuanqG1EYR3L",
          //"http://api.rari.capital:21917/",
      },
      gasPrice:"auto",
    },
    development: {
      url: "http://localhost:8545",
    }
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
  }
};