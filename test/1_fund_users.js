const chai = require("chai");

const hre = require("hardhat");
const ethers = hre.ethers;
const waffle = hre.waffle;
const provider = waffle.provider;

const BigNumber = require("bn.js");

const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const usedToken = require("./helpers/token").token;
const borrowedToken = require("./helpers/token").borrowing;

const token = usedToken.underlying;
const symbol = usedToken.symbol;
const userAddress = usedToken.user;
const depositNumber = usedToken.depositAmount;

const tokens = require("./helpers/tokens");
const contracts = require("./helpers/contracts");

const erc20Abi = require("./abi/ERC20.json");

let rariFundManager;
let rariFundController;

let owner, rebalancer, user;

async function deploy() {
  [owner, rebalancer] = await ethers.getSigners();
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [userAddress],
  });

  user = await ethers.provider.getSigner(userAddress);

  //prettier-ignore
  const RariFundManager = await ethers.getContractFactory("RariFundManager");
  //prettier-ignore
  const RariFundController = await ethers.getContractFactory("RariFundController");

  rariFundManager = await RariFundManager.deploy();
  await rariFundManager.deployed();

  rariFundController = await RariFundController.deploy(
    rariFundManager.address,
    rebalancer.address,
    contracts.comptroller,
    contracts.priceFeed,
    contracts.rariFundManager
  );
  await rariFundController.deployed();

  await rariFundManager.setRariFundController(rariFundController.address);

  for (let i = 0; i < tokens.length; i++) {
    await rariFundController
      .newTank(tokens[i].token, borrowedToken)
      .catch((error) => console.log(error));
  }
}

console.log("\n");
console.log("Token Chosen at Random: ", usedToken.symbol);

describe("RariFundManager", async () => {
  before(async () => {
    await deploy().catch((error) => console.log(error));
  });

  it("Reverts if the currency is not supported", async () => {
    await rariFundManager.deposit("NONE", 5).should.be.rejectedWith("revert");
  });

  it("Sends funds to the RariFundTank", async () => {
    const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);

    await tokenContract
      .connect(user)
      .approve(rariFundController.address, depositNumber);

    await rariFundManager.connect(user).deposit(symbol, depositNumber);
    await rariFundController
      .getDormantFunds(token)
      .should.eventually.equal(depositNumber);
  });

  it("Reverts if deposit amount is too low", async () => {
    // Note that DAI, which is being used in this example is pegged to 1 USD
    const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);

    await tokenContract.approve(rariFundManager.address, 2);
    await rariFundManager
      .connect(user)
      .deposit(symbol, 1)
      .should.be.rejectedWith("revert");
  });
});
