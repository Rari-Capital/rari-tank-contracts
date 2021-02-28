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
let rariTankFactory, rariDataProvider, tank, wbtc;
let user, deployer, rebalancer;


describe("RariDataProvider, RariTankDelegate, RariTankDelegator", async function() {
    this.timeout(300000)
    before(async () => {
        user = await ethers.provider.getSigner(constants.WBTC_HOLDER);
        deployer = await ethers.provider.getSigner(constants.FUSE_DEPLOYER);

        [rariTankFactory, rariDataProvider, rariTankDelegator] = await contracts;
        tank = new ethers.Contract(rariTankDelegator, RariTankDelegatorABI, user);
        wbtc = await ethers.getContractAt(ERC20ABI, constants.WBTC);
        [rebalancer] = await ethers.getSigners();
    });

    describe("Fuse interactions", async () => {
        it("Supplies funds to Fuse, mints fTokens", async () => {
            await rariTankFactory.rebalance(tank.address);
        });

        it("Borrows USDC from Fuse", async () => {

        });
    });

    describe("Stable Pool Interactions", async () => {
        it("Deposits into stable pool, mints RSPT", async () => {});

    });

    describe("Withdrawals", async () => {
        before(async () => {}); // Withdraw funds
        it("Repays borrowed funds", async () => {

        });

        it("Withdraws supplied WBTC", async () => {})

    });

});