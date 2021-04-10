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

      await rariTankFactory
        .deployTank(
          constants.EXAMPLE_TOKEN,
          constants.FUSE_COMPTROLLER,
          constants.ROUTER,
          tankDelegate.address
        )
        .should.not.be.rejectedWith("revert");
    });

    it("Reverts if Tanks has already been created", async () => {
      await rariTankFactory
        .deployTank(
          constants.TOKEN,
          constants.FUSE_COMPTROLLER,
          constants.ROUTER,
          tankDelegate.address
        )
        .should.be.rejectedWith("revert RariTankFactory");
    });

    it("Returns correct tank address", async () => {
      chai.expect(
        (await rariTankFactory.getTank(
          token.address,
          constants.FUSE_COMPTROLLER,
          tankDelegate.address
        )) != ethers.constants.AddressZero
      );
    });
  });

  describe("Delivers tank-related data correctly (1 factor)", async () => {
    it(`Returns the one tank that uses ${constants.TOKEN_SYMBOL}`, async () => {
      chai.expect(
        (await rariTankFactory.getTanksByToken(constants.TOKEN)).length == 1
      );
    });

    it("Returns both tanks that use the same Comptroller", async () => {
      chai.expect(
        (await rariTankFactory.getTanksByComptroller(constants.TOKEN)).length ==
          2
      );
    });

    it("Returns both tanks that use the same implementation", async () => {
      chai.expect(
        (await rariTankFactory.getTanksByImplementation(constants.TOKEN))
          .length == 2
      );
    });
  });

  describe("Delivers tank-related data correct (multi-factor)", async () => {
    it("Returns one tank, even if the comptroller is shared", async () => {
      chai.expect(
        (
          await rariTankFactory.getTanksByTokenAndComptroller(
            constants.TOKEN,
            constants.FUSE_COMPTROLLER
          )
        ).length == 1
      );
    });
    it("Returns one tank, even if the implementation is shared", async () => {
      chai.expect(
        (
          await rariTankFactory.getTanksByTokenAndImplementation(
            constants.TOKEN,
            tankDelegate.address
          )
        ).length == 1
      );
    });
    it("Returns both tanks", async () => {
      chai.expect(
        (
          await rariTankFactory.getTanksByComptrollerAndImplementation(
            constants.FUSE_COMPTROLLER,
            tankDelegate.address
          )
        ).length == 2
      );
    });
  });
});
