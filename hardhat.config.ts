require("@nomiclabs/hardhat-ganache");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-waffle");
require("solidity-coverage");

const removeConsoleLog = require("hardhat-preprocessor");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      forking: {
        url:
          "https://eth-mainnet.alchemyapi.io/v2/UPMBuJ4TAQrsy9sdb4QSKuanqG1EYR3L",
      },
    },
    development: {
      url: "http://localhost:8546",
    }
  },
  compilers: [{ version: "0.7.3" }, { version: "0.6.6" }],
  // preprocess: {
    //   eachLine: removeConsoleLog(
      //     (bre: any) =>
      //       bre.network.name !== "hardhat" && bre.network.name !== "localhost"
      //   ),
      // },
};

//11875994