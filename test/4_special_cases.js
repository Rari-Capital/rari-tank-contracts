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

  describe("Rebalances", async () => {
    it("Borrows funds and registers profit", async () => {
      const dai = await ethers.getContractAt(ERC20ABI, constants.DAI);
      const dai_holder = await ethers.provider.getSigner(constants.DAI_HOLDER);

      const depositAmount = constants.AMOUNT;
      await token.connect(user).approve(rariTankDelegator, depositAmount);
      await tank.deposit(depositAmount);

      dai
        .connect(dai_holder)
        .transfer(constants.RARI_FUND_CONTROLLER, "1000000000000000000000000");

      await rariTankFactory
        .connect(keeper)
        .rebalance(tank.address, constants.USE_WETH);
    });

    it("Repays funds and registers profit", async () => {
      const dai = await ethers.getContractAt(ERC20ABI, constants.DAI);
      const daiHolder = await ethers.provider.getSigner(constants.DAI_HOLDER);

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [tank.address],
      });
      const tankSigner = await ethers.provider.getSigner(tank.address);

      const cTokenAddress = await tank.cToken();
      const cToken = await ethers.getContractAt(CERC20ABI, cTokenAddress);

      const withdrawalAmount = ethers.BigNumber.from(constants.AMOUNT)
        .div(3)
        .toString();

      await user.sendTransaction({
        to: tank.address,
        value: ethers.utils.parseEther("1.0"),
      });
      cToken.connect(tankSigner).redeemUnderlying(withdrawalAmount);

      dai
        .connect(daiHolder)
        .transfer(constants.RARI_FUND_CONTROLLER, "1000000000000000000000000");

      await rariTankFactory
        .connect(keeper)
        .rebalance(tank.address, constants.USE_WETH);
    });
  });
});
