require("@nomiclabs/hardhat-waffle");
require("solidity-coverage");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      forking: {
        url:
          "https://eth-mainnet.alchemyapi.io/v2/UPMBuJ4TAQrsy9sdb4QSKuanqG1EYR3L",
        blockNumber: 11635038,
      },
    },
  },
  solidity: "0.7.3",
};
