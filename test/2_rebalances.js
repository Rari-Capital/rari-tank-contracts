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
let rariTankFactory, tank, token, keeper;
let user, deployer, rebalancer;


describe("RariTankDelegate, RariTankDelegator", async function() {
    this.timeout(300000)
    before(async () => {
        user = await ethers.provider.getSigner(constants.HOLDER);
        deployer = await ethers.provider.getSigner(constants.FUSE_DEPLOYER);

        [rariTankFactory, rariTankDelegator, keeper] = await contracts;
        tank = new ethers.Contract(rariTankDelegator, RariTankDelegatorABI, user);
        token = await ethers.getContractAt(ERC20ABI, constants.TOKEN);
        [rebalancer] = await ethers.getSigners();
    });

    describe("External interactions", async () => {
        it("Supplies funds to Fuse, mints fTokens", async () => {
            await rariTankFactory.connect(keeper).rebalance(tank.address);
            const cTokenContract = await tank.cToken();
            const cToken = await ethers.getContractAt(ERC20ABI, cTokenContract);
            chai.expect((await cToken.balanceOf(tank.address)).gt(0));
        });

        it("Borrows DAI, deposits into stable pool, mints RDPT", async () => {
            const rspt = await ethers.getContractAt(ERC20ABI, constants.RSPT);
            chai.expect((await rspt.balanceOf(tank.address)).gt(0));
        });

        it("Earning yield increases exchangeRate", async () => {
            const dai = await ethers.getContractAt(ERC20ABI, constants.DAI);
            const dai_holder = await ethers.provider.getSigner(constants.DAI_HOLDER);
            
            dai.connect(dai_holder).transfer(constants.RARI_FUND_CONTROLLER, "1000000000000000000000000");

            await hre.network.provider.request({
                method: "evm_mine",
            });
            
            await rariTankFactory.connect(keeper).rebalance(tank.address);
        })
    });

    describe("Withdrawals", async () => {
        it("Able to withdraw more than initial deposit", async () => {
            console.log((await tank.callStatic.underlyingBalanceOf(constants.HOLDER)).toString());
            await tank.connect(user).withdraw(constants.WITHDRAWAL_AMOUNT);
        });

        it("Reverts if withdrawal amount is too large", async () => {
            await tank.connect(user).withdraw(constants.LARGE_WITHDRAWAL_AMOUNT).should.be.rejectedWith("revert RariTankDelegate");
        });

        it("Dormant funds can be used for withdrawals", async () => {
            //The constants.WITHDRAWAL_AMOUNT will be less than constants.AMOUNT (because of Keep3r Fee)
            token.connect(user).approve(rariTankDelegator, constants.WITHDRAWAL_AMOUNT);
            await tank.connect(user).deposit(constants.WITHDRAWAL_AMOUNT);
            await tank.connect(user).withdraw(constants.AMOUNT).should.be.not.rejectedWith("revert");
        });

        it("Withdraws if amount is less than dormant", async () => {
            // constants.amount is less than constants.withdrawal_amount
            token.connect(user).approve(rariTankDelegator, constants.LARGE_WITHDRAWAL_AMOUNT);
            await tank.connect(user).deposit(constants.LARGE_WITHDRAWAL_AMOUNT);
            await tank.connect(user).withdraw(constants.AMOUNT).should.be.not.rejectedWith("revert");
        })
    });
});