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
let rariTankFactory, rariDataProvider, tank, wbtc, keeper;
let user, deployer;

describe("RariTankDelegator, RariTankDelegate, RariDataProvider", async function() {
    this.timeout(300000)
    before(async () => {
        user = await ethers.provider.getSigner(constants.WBTC_HOLDER);
        deployer = await ethers.provider.getSigner(constants.FUSE_DEPLOYER);

        [rariTankFactory, rariDataProvider, rariTankDelegator, keeper] = await contracts;
        tank = new ethers.Contract(rariTankDelegator, RariTankDelegatorABI, user);
        console.log("\n\n\n\n\n");
        wbtc = await ethers.getContractAt(ERC20ABI, constants.WBTC);
        console.log("RariTankDelegator, RariTankDelegate, RariDataProvider");
    })

    describe("Deposits function correctly", async () => {
        it("Accepts funds, mints the RariTankToken", async () => {
            await wbtc.connect(user).approve(rariTankDelegator, "100000000");
            await tank.deposit("100000000");
            chai.expect((await tank.totalSupply()).gt(0));
        });

        it("Reverts if deposit amount is below $500", async () => {
            await wbtc.connect(user).approve(rariTankDelegator, "100000000");
            await tank.deposit(10).should.be.rejectedWith("revert RariTankDelegate");
        });
    });
});