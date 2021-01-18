const chai = require("chai");

const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const tokenAddresses = require("./helpers/token");

const usedToken = tokenAddresses.token;

const token = usedToken.underlying;
const symbol = usedToken.symbol;
const userAddress = usedToken.user;
const depositNumber = usedToken.depositAmount;

const poolToken = tokenAddresses.rspt;
const borrowing = tokenAddresses.borrowing;

const tokens = require("./helpers/tokens");
const contracts = require("./helpers/contracts");

const erc20Abi = require("./abi/ERC20.json");
const cerc20Abi = require("./abi/CERC20.json");
const { assert } = require("console");

const { time } = require("@openzeppelin/test-helpers");

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
      .newTank(tokens[i].token, borrowing)
      .catch((error) => console.log(error));
  }
}

describe("RariFundController, RariFundTanks", async () => {
  before(async () => {
    await deploy().catch((error) => console.log(error));
  });

  describe("Unused Funds", async () => {
    it("Supplies assets to Compound and mints cTokens", async () => {
      const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);

      await tokenContract
        .connect(user)
        .approve(rariFundController.address, depositNumber);

      await rariFundManager.connect(user).deposit(symbol, depositNumber);
      await rariFundController.connect(rebalancer).rebalance(token);

      x = await tokenContract.balanceOf(rariFundController.getTank(token));
    });

    it("Borrows assets from Compound", async () => {
      const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);

      await tokenContract
        .balanceOf(rariFundController.getTank(token))
        .then((res) => assert(res.gt(0)));
    });
  });

  describe("Rari Stable Pool Interactions", async () => {
    it("Deposits into Rari and Mints RSPT", async () => {
      const rsptContract = await hre.ethers.getContractAt(erc20Abi, poolToken);

      await rsptContract
        .balanceOf(rariFundController.getTank(token))
        .then((res) => assert(res.gt(0)));
    });
  });

  describe("Withdrawals ", async () => {
    it("Withdraws funds from protocols", async () => {
      const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);

      await time.advanceBlock();
      await rariFundController.connect(rebalancer).rebalance(token);
      await rariFundManager.connect(user).withdraw(symbol, depositNumber);
    });
  });
});
