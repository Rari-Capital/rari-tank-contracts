const hre = require("hardhat");
const ethers = hre.ethers;

const BN = require("bn.js");

const chai = require("chai");
const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const contracts = require("./helpers/deploy");
const constants = require("./helpers/constants");

const RariTankDelegatorABI = require("./abi/RariFundTank.json");
const ERC20ABI = require("./abi/ERC20.json");
const CERC20ABI = require("./abi/CERC20.json");

let RariTankFactory;
let user, deployer, rebalancer;
let rariTankFactory, tank, token, keeper;

async function upgradeProxy() {
  const implementation = await RariTankFactory.deploy();
  await implementation.deployed();

  return implementation.address;
}

describe("Contract upgradeability", async function () {
  this.timeout(300000);
  before(async () => {
    user = await ethers.provider.getSigner(constants.HOLDER);
    deployer = await ethers.provider.getSigner(constants.FUSE_DEPLOYER);

    [rariTankFactory, rariTankDelegator, keeper] = await contracts;
    tank = new ethers.Contract(rariTankDelegator, RariTankDelegatorABI, user);
    token = await ethers.getContractAt(ERC20ABI, constants.TOKEN);
    [rebalancer, testing] = await ethers.getSigners();

    RariTankFactory = await ethers.getContractFactory("RariTankFactory");
  });

  describe("Upgrades are safe", async () => {
    it("Factory can be upgraded", async () => {
      await rariTankFactory.upgradeProxy(upgradeProxy());
    });

    it("Factory data is saved", async () => {
      const tankAddress = await rariTankFactory.tanks(0);
      await rariTankFactory.upgradeProxy(upgradeProxy());
      chai.expect((await rariTankFactory.tanks(0)) == tankAddress);
    });
  });
});
