/**
 * The following tests are based around the user experience (deposits, withdrawals) on the highest level
 * Contracts used: RariFundManager, RariFundController, RariFundTank
 */

const chai = require("chai");
const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const RariFundManager = artifacts.require("RariFundManager");
const RariFundController = artifacts.require("RariFundController");
const ERC20ABI = require("./abi/ERC20.json");

const tokens = require("./helpers/tokens").tokens;
const erc20Contracts = tokens.map(
  (token) => new web3.eth.Contract(ERC20ABI, token)
);

contract("RariFundManager, RariFundController", async (accounts) => {
  const [owner, , user] = accounts;
  const [token] = tokens;
  const [tokenContract] = erc20Contracts;

  before(async () => {
    // Ran before tests

    await tokenContract.methods
      .transfer(user, 10000)
      .send({ from: "0x66c57bf505a85a74609d2c83e94aabb26d691e1f" });

    rariFundManager = await RariFundManager.deployed();
    rariFundController = await RariFundController.deployed();

    tank = await rariFundController.getTank(token);
  });

  it("Reverts if currency is not supported", async () => {
    await rariFundManager
      .deposit(owner, 10000)
      .should.be.rejectedWith("revert");
  });

  it("Sends funds to the RariFundTank", async () => {
    await tokenContract.methods.approve(tank, 10000).send({ from: user });

    await rariFundManager.deposit("DAI", 10000, {
      from: user,
    });
    await tokenContract.methods
      .balanceOf(tank)
      .call()
      .should.eventually.bnEqual(10000);
  });
});
