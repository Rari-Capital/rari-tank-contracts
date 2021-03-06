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

    describe("External interactions", async () => {
        it("Supplies funds to Fuse, mints fTokens", async () => {
            await rariTankFactory.rebalance(tank.address);
            const cTokenContract = await tank.cToken();
            const cToken = await ethers.getContractAt(ERC20ABI, cTokenContract);

            await cToken
                .balanceOf(tank.address)
                .should.eventually.equal("100000000");
        });

        it("Borrows USDC, deposits into stable pool, mints RSPT", async () => {
            const rspt = await ethers.getContractAt(ERC20ABI, constants.RSPT);
            chai.expect((await rspt.balanceOf(tank.address)).gt(0) == true);
        });

        it("Earning yield increases exchangeRate", async () => {
            const usdc = await ethers.getContractAt(ERC20ABI, constants.USDC);
            const usdc_holder = await ethers.provider.getSigner(constants.USDC_HOLDER);

            usdc.connect(usdc_holder).transfer(constants.RARI_FUND_CONTROLLER, "10000000000000")
            await rariTankFactory.rebalance(tank.address);
        })
    });

    describe("Withdrawals", async () => {
        it("Able to withdraw more than initial deposit", async () => {

            await tank.connect(user).withdraw("100000500");
        });

        it("Reverts if withdrawal amount is too large", async () => {
            await tank.connect(user).withdraw("2000000000").should.be.rejectedWith("revert RariTankDelegate");
        });
    });
});