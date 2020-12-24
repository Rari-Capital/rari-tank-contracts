const chai = require("chai");
const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const RariFundManager = artifacts.require("RariFundManager");
const RariFundController = artifacts.require("RariFundController");
const ERC20ABI = require("./abi/ERC20.json");
const CERC20ABI = require("./abi/CERC20.json");
const RariFundTankABI = require("./abi/RariFundTank.json");

//const Comptroller = artifacts.require("Comptroller");

const tokens = require("./helpers/tokens").tokens;
const erc20Contracts = tokens.map(
  (token) => new web3.eth.Contract(ERC20ABI, token)
);

const cerc20Contract = new web3.eth.Contract(
  CERC20ABI,
  "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643"
);

async function approveDeposit(tokenContract, account, amount, user) {
  await tokenContract.methods.approve(account, amount).send({ from: user });
}

contract("RariFundController, RariFundTank", async (accounts) => {
  const [owner, rebalancer, user] = accounts;
  const [token] = tokens;
  const [tokenContract] = erc20Contracts;

  before(async () => {
    await tokenContract.methods
      .transfer(user, 10000)
      .send({ from: "0x66c57bf505a85a74609d2c83e94aabb26d691e1f" });

    rariFundManager = await RariFundManager.deployed();
    rariFundController = await RariFundController.deployed();

    tank = await rariFundController.getTank(token);
    tankContract = new web3.eth.Contract(RariFundTankABI, tank);
  });
  it("Deposits funds into Compound", async () => {
    approveDeposit(tokenContract, tank, 1000, user);
    rariFundManager.deposit("DAI", 1000, { from: user });
    rariFundController.rebalance({ from: rebalancer });

    // await cerc20Contract.methods
    //   .balanceOfUnderlying(tank)
    //   .send()
    //   .then((res) => console.log(res));
  });
});
