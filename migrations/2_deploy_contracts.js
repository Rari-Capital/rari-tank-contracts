const tokens = require("./helpers/tokens").tokens;
const contracts = require("./helpers/contracts").contracts;

const RariFundManager = artifacts.require("RariFundManager");
const RariFundController = artifacts.require("RariFundController");
const RariFundTank = artifacts.require("RariFundTank");
const CompoundPoolController = artifacts.require("CompoundPoolController");

module.exports = async (deployer, network, accounts) => {
  const owner = accounts[0];
  //Deploy the RariFundManager and RariFundController
  await deployer.link(CompoundPoolController, RariFundController);
  await deployer.deploy(RariFundManager, { from: owner }).then(async () => {
    await deployer
      .deploy(RariFundController, { from: owner })
      .then(async () => {
        console.log(RariFundController.address);

        const managerInstance = await RariFundManager.deployed();
        const controllerInstance = await RariFundController.deployed();

        managerInstance.initialize(RariFundController.address);
        controllerInstance.initialize(RariFundManager.address);

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
