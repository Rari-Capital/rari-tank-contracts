const tokens = require("./helpers/tokens").tokens;
const contracts = require("./helpers/contracts").contracts;

const RariFundManager = artifacts.require("RariFundManager");
const RariFundController = artifacts.require("RariFundController");
const CompoundPoolController = artifacts.require("CompoundPoolController");

module.exports = async (deployer, network, accounts) => {
  const [owner, rebalancer] = accounts;

  //Address with the least slippage in the Rari Stable Pool
  const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

  //Deploy the RariFundManager and RariFundController
  await deployer.link(CompoundPoolController, RariFundController);
  await deployer.deploy(RariFundManager, { from: owner }).then(async () => {
    await deployer
      .deploy(RariFundController, { from: owner })
      .then(async () => {
        const managerInstance = await RariFundManager.deployed();
        const controllerInstance = await RariFundController.deployed();

        managerInstance.initialize(RariFundController.address);
        controllerInstance.initialize(
          RariFundManager.address,
          rebalancer,
          USDC
        );

        tokens.map((token) => {
          controllerInstance.newTank(
            token,
            contracts.comptroller,
            contracts.priceFeed,
            { from: owner }
          );
        });
      });
  });
};
