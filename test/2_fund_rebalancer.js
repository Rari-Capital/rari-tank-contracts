const chai = require("chai");

const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const tokenAddresses = require("./helpers/token");

const token = tokenAddresses.underlying;
const cToken = tokenAddresses.cToken;
const borrowing = tokenAddresses.borrowing;

const tokens = require("./helpers/tokens");
const contracts = require("./helpers/contracts");

const erc20Abi = require("./abi/ERC20.json");
const cerc20Abi = require("./abi/CERC20.json");

let rariFundManager;
let rariFundController;

let owner, rebalancer, user;

async function deploy() {
  [owner, rebalancer] = await ethers.getSigners();
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: ["0x66c57bf505a85a74609d2c83e94aabb26d691e1f"],
  });

  user = await ethers.provider.getSigner(
    "0x66c57bf505a85a74609d2c83e94aabb26d691e1f"
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
    contracts.priceFeed
  );
  await rariFundController.deployed();
  await rariFundManager.setRariFundController(rariFundController.address);

  for (let i = 0; i < tokens.length; i++) {
    await rariFundController
      .newTank(tokens[i].token, tokens[i].decimals)
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
      const depositAmount = "1000000000000000000000";
      await tokenContract
        .connect(user)
        .approve(rariFundController.address, depositAmount);

      await rariFundManager.connect(user).deposit("DAI", depositAmount);
      await rariFundController.connect(rebalancer).handleUnusedFunds(borrowing);

      x = await tokenContract.balanceOf(rariFundController.getTank(token));
    });

    it("Borrows assets from Compound", async () => {
      const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);

      x = await tokenContract.balanceOf(rariFundController.getTank(token));
    });
    it("Does not depositUnusedFunds if there are none", async () => {});
    it("Values are reset after funds are deposited", async () => {});
  });

  describe("Rari Stable Pool Interactions", async () => {
    it("Deposits into Rari", async () => {});
    it("Stores RSPT", async () => {});
    it("Withdraws funds from Rari", async () => {});
  });

  describe("Borrow amount", async () => {
    it("Keeps the borrow balance at 50% of borrow amount", async () => {});
    it("Uses Unused Funds", async () => {});
  });
});
