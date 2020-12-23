/**
 * The following tests are used to ensure that the contracts can deposit into Compound + Rari
 * Contracts used: RariFundManager, RariFundController, RariFundTank
 */

const { BN, ether, balance } = require("@openzeppelin/test-helpers");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);
chai.should();

const RariFundManager = artifacts.require("RariFundManager");
const RariFundController = artifacts.require("RariFundController");
const ERC20ABI = require("./abi/ERC20.json");

const tokens = require("./helpers/tokens").tokens;
const erc20Contracts = tokens.map(
  (token) => new web3.eth.Contract(ERC20ABI, token)
);

contract("RariFundManager", (accounts) => {
  const [owner, user] = accounts;
  const [token] = tokens;
  const [tokenContract] = erc20Contracts;

  console.log(tokenContract);

  tokenContract.methods
    .transfer(user, 10000)
    .send({ from: "0x66c57bf505a85a74609d2c83e94aabb26d691e1f" });

  balance
    .current("0x66c57bf505a85a74609d2c83e94aabb26d691e1f")
    .then((cash) => console.log(cash.toString()));

  beforeEach(async () => {
    // Ran before every test
    rariFundManager = await RariFundManager.deployed();
    rariFundController = await RariFundController.deployed();

    rariFundManager.getRariFundController().then((addr) => console.log(addr));
  });

  it("Allows owner to set new RariFundController", async () => {
    await rariFundManager
      .setRariFundController(RariFundController.address, { from: owner })
      .should.not.be.rejectedWith("revert");
  });

  it("Reverts if RariFundController setter isn't an owner", async () => {
    await rariFundManager
      .setRariFundController(RariFundController.address, { from: user })
      .should.be.rejectedWith("revert");
  });

  it("Reverts if currency is not supported", async () => {
    await rariFundManager
      .deposit(owner, 10000)
      .should.be.rejectedWith("revert");
  });
  it("Sends funds to the RariFundTank", async () => {
    await rariFundManager.deposit("DAI", 10000, {
      from: owner,
    });
    await tokenContract.methods.balanceOf(rariFundController.getTank(token));
  });
});
