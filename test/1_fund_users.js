const chai = require("chai");

const hre = require("hardhat");
const ethers = hre.ethers;
const waffle = hre.waffle;
const provider = waffle.provider;

const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const token = require("./helpers/token");
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
      .newTank(tokens[i])
      .catch((error) => console.log(error));
  }
}

describe("RariFundManager", async () => {
  before(async () => {
    await deploy().catch((error) => console.log(error));
  });

  it("Reverts if the currency is not supported", async () => {
    await rariFundManager.deposit("NONE", 50).should.be.rejectedWith("revert");
  });

  it("Sends funds to the RariFundTank", async () => {
    const tokenContract = await hre.ethers.getContractAt(erc20Abi, token);

    await tokenContract
      .connect(user)
      .approve(rariFundController.address, 1000000);

    await tokenContract.connect(user).approve(rariFundController.address, 100);
    await rariFundManager.connect(user).deposit("DAI", 10);

    await rariFundController
      .getTotalTokensLocked(token)
      .should.eventually.bnEqual(10);
  });
});
