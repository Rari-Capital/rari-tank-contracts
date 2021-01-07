const tokens = require("./helpers/tokens").tokens;
const contracts = require("./helpers/contracts").contracts;

const RariFundManager = artifacts.require("RariFundManager");
const RariFundController = artifacts.require("RariFundController");
const CompoundPoolController = artifacts.require("CompoundPoolController");

module.exports = async (deployer, network, accounts) => {
  const [owner, rebalancer] = accounts;

  await deployer.deploy(RariFundManager, { from: owner }).then(async () => {
    await deployer.link(CompoundPoolController, RariFundController);
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

// module.exports = async (deployer, _, accounts) => {
//   const [owner, rebalancer] = accounts;

//   //deployer.link(CompoundPoolController, RariFundController);

//   deployer.then(async () => {
//     await deployer.deploy(RariFundManager);
//     await deployer.deploy(RariFundController, RariFundManager.address);

//     const rariFundManager = await RariFundManager.deployed();
//     rariFundManager.setRariFundController(RariFundController.address);
//   });
// };
