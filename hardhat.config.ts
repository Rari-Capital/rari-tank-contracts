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
        url: "http://api.rari.capital:21917/",
        blockNumber: 11,
        //url:
          //"https://eth-mainnet.alchemyapi.io/v2/UPMBuJ4TAQrsy9sdb4QSKuanqG1EYR3L",
      },
    },
    development: {
      url: "http://api.rari.capital:21917/",
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
