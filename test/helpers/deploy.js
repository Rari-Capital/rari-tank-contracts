const contracts = require("./constants");
const hre = require("hardhat");
const ethers = hre.ethers;
const web3 = hre.web3;

const Fuse = require("./fuse-sdk/src/index");
const fuse = new Fuse(web3.currentProvider);

const addresses = require("./constants");
const selectedAccount = addresses.FUSE_DEPLOYER;
const [dai, token] = [addresses.DAI, addresses.TOKEN];
const [daiHolder, tokenHolder] = [addresses.DAI_HOLDER, addresses.HOLDER];

const Keep3rABI = require("../abi/Keep3r.json");
const FactoryABI = require("../abi/Factory.json");
const Keep3rOracleABI = require("../abi/Oracle.json");

async function impersonateAccounts() {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [addresses.KEEP3R_GOVERNANCE],
  });

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [addresses.DAI_HOLDER],
  });
}

async function deploy() {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [tokenHolder],
  });

  await impersonateAccounts();

  const RariTankFactory = await ethers.getContractFactory("RariTankFactory");
  const RariTankDelegate = await ethers.getContractFactory("RariTankDelegate");
  const FactoryDelegator = await ethers.getContractFactory("FactoryDelegator");

  const tankDelegate = await RariTankDelegate.deploy();
  await tankDelegate.deployed();

  const factory = await RariTankFactory.deploy();
  await factory.deployed();

  let rariTankFactory = await FactoryDelegator.deploy(factory.address);
  await rariTankFactory.deployed();

  rariTankFactory = await ethers.getContractAt(
    FactoryABI,
    rariTankFactory.address
  );

  // Add the tank factory as a Keep3r job
  const governance = await ethers.provider.getSigner(
    addresses.KEEP3R_GOVERNANCE
  );
  const keep3r = await ethers.getContractAt(Keep3rABI, addresses.KEEP3R);

  keep3r.connect(governance).addJob(rariTankFactory.address);

  await rariTankFactory.newImplementation(tankDelegate.address);
  await rariTankFactory.deployTank(
    token,
    addresses.FUSE_COMPTROLLER,
    addresses.ROUTER,
    1
  );

  const tank = await rariTankFactory.getTank(
    addresses.TOKEN,
    addresses.FUSE_COMPTROLLER,
    1
  );

  const oracle = await ethers.getContractAt(
    Keep3rOracleABI,
    addresses.KEEP3R_ORACLE
  );

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [addresses.ORACLE_BOT],
  });

  const bot = await ethers.provider.getSigner(addresses.ORACLE_BOT);
  oracle
    .connect(bot)
    .update(
      "0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44",
      "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
    );

  return [rariTankFactory, tank, bot, tankDelegate];
}

module.exports = deploy();
