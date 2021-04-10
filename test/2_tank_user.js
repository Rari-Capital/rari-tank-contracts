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
let user, deployer;
let rariTankFactory, tank, token, keeper;

describe("User Interactions", async function () {
  this.timeout(300000);
  before(async () => {
    user = await ethers.provider.getSigner(constants.HOLDER);
    deployer = await ethers.provider.getSigner(constants.FUSE_DEPLOYER);

    [rariTankFactory, rariTankDelegator, keeper] = await contracts;
    tank = new ethers.Contract(rariTankDelegator, RariTankDelegatorABI, user);
    token = await ethers.getContractAt(ERC20ABI, constants.TOKEN);
  });

  describe("Deposits function correctly", async () => {
    it("Accepts funds, mints the RariTankToken", async () => {
      const depositAmount = constants.AMOUNT;
      await token.connect(user).approve(rariTankDelegator, depositAmount);
      await tank.deposit(depositAmount);
      chai.expect((await tank.totalSupply()).gt(0));
    });

    it("Supplies collateral to Fuse, mints cTokens", async () => {
      const cTokenContract = await tank.cToken();
      const cToken = await ethers.getContractAt(ERC20ABI, cTokenContract);
      chai.expect((await cToken.balanceOf(tank.address)).gt(0));
    });

    it("Reverts if deposit amount is below 1 ETH", async () => {
      await token.connect(user).approve(rariTankDelegator, "100000"); //Should be too small for every asset
      await tank.deposit(10).should.be.rejectedWith("revert RariTankDelegate");
    });
  });
});
