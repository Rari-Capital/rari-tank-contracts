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

const token = require("./helpers/token").underlying;
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
    params: ["0x2bc812c70dcd634a07ce4fb9cd9ba4319fd9898d"],
  });

  user = await ethers.provider.getSigner(
    "0x2bc812c70dcd634a07ce4fb9cd9ba4319fd9898d"
  );

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
      .newTank(tokens[i].token, tokens[i].decimals)
      .catch((error) => console.log(error));
  }
}

describe("RariFundManager", async () => {
  before(async () => {
    await deploy().catch((error) => console.log(error));
  });

  it("Reverts if the currency is not supported", async () => {
    await rariFundManager.deposit("NONE", 5).should.be.rejectedWith("revert");
  });

  it("Sends funds to the RariFundTank", async () => {
    const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);
    const depositNumber = "2000000000000000000000";

    await tokenContract
      .connect(user)
      .approve(rariFundController.address, depositNumber);

    await rariFundManager.connect(user).deposit("ZRX", depositNumber);
    await rariFundController
      .getTotalTokensLocked(token)
      .should.eventually.bnEqual(depositNumber);
  });

  it("Reverts if deposit amount is too low", async () => {
    // Note that DAI, which is being used in this example is pegged to 1 USD
    const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);
    const depositNumber = "100";

    await tokenContract.approve(rariFundController.address, depositNumber);
    await rariFundManager
      .connect(user)
      .deposit("ZRX", depositNumber)
      .should.be.rejectedWith("revert");
  });
});
