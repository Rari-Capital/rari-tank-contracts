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

let rariTankFactory, tank, token, keeper;
let user, deployer, rebalancer;

describe("Special Cases", async function () {
  this.timeout(300000);
  before(async () => {
    user = await ethers.provider.getSigner(constants.HOLDER);
    deployer = await ethers.provider.getSigner(constants.FUSE_DEPLOYER);

    [rariTankFactory, rariTankDelegator, keeper] = await contracts;
    tank = new ethers.Contract(rariTankDelegator, RariTankDelegatorABI, user);
    token = await ethers.getContractAt(ERC20ABI, constants.TOKEN);
    [rebalancer] = await ethers.getSigners();
  });

  describe("Mints", async () => {
    it("RTT has been minted", async () => {
      chai.expect((await tank.totalSupply()).gt(0));
    });

    it("User has been minted RTT", async () => {
      chai.expect((await tank.balanceOf(constants.HOLDER)).gt(0));
    });
  });

  describe("Transfers", async () => {
    it("User can transfer RTT", async () => {
      await tank.transfer(constants.DAI_HOLDER, 100);
      chai.expect((await tank.balanceOf(constants.DAI_HOLDER)).eq(100));
    });

    //it("Users can safe transfer RTT");
  });
});
