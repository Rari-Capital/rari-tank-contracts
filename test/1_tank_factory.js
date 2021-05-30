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
let rariTankFactory, rariTankDelegator, tankDelegate, tank, token, keeper;

describe(`USING ${constants.TOKEN_SYMBOL}\n\nRariTankFactory`, async function () {
  this.timeout(300000);
  before(async () => {
    user = await ethers.provider.getSigner(constants.HOLDER);
    deployer = await ethers.provider.getSigner(constants.FUSE_DEPLOYER);

    [rariTankFactory, rariTankDelegator, , tankDelegate] = await contracts;
    tank = new ethers.Contract(rariTankDelegator, RariTankDelegatorABI, user);
    token = await ethers.getContractAt(ERC20ABI, constants.TOKEN);
  });

  describe("Tank deployment", async () => {
    it("Deploys an instance of the RariTankDelegator", async () => {
      chai.expect((await ethers.provider.getCode(rariTankDelegator)) != "0x");
    });

    it("Reverts if Tanks has already been created", async () => {
      await rariTankFactory
        .deployTank(
          constants.TOKEN,
          constants.FUSE_COMPTROLLER,
          constants.ROUTER,
          1
        )
        .should.be.rejectedWith("revert RariTankFactory");
    });

    it("Returns correct tank address", async () => {
      chai.expect(
        (await rariTankFactory.getTank(
          token.address,
          constants.FUSE_COMPTROLLER,
          1
        )) != ethers.constants.AddressZero
      );
    });
  });
});
