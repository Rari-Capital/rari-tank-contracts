const contracts = require("./constants");
const hre = require("hardhat");
const ethers = hre.ethers;
const web3 = hre.web3;

const prompt = require('prompt-sync')();
const Fuse = require("./fuse-sdk/src/index");
const fuse = new Fuse(web3.currentProvider);

const addresses = require("./constants");
const selectedAccount = addresses.FUSE_DEPLOYER;
const [dai, token] = [addresses.DAI, addresses.TOKEN];
const [daiHolder, tokenHolder] = [addresses.DAI_HOLDER, addresses.HOLDER];

const Keep3rABI = require("../abi/Keep3r.json");
const Keep3rOracleABI = require("../abi/Oracle.json")

async function deployFuse() {
  const preferredPriceOracle = await fuse.deployPriceOracle(
    "PreferredPriceOracle",
    { isPublic: true },
    { from: selectedAccount }
  );

  let comptroller = new web3.eth.Contract(
    JSON.parse(
      fuse.compoundContracts["contracts/Comptroller.sol:Comptroller"].abi
    )
  );
  comptroller = await comptroller
    .deploy({
      data:
        "0x" +
        fuse.compoundContracts["contracts/Comptroller.sol:Comptroller"].bin,
    })
    .send({ from: selectedAccount });

  var cErc20 = new web3.eth.Contract(
    JSON.parse(
      fuse.compoundContracts["contracts/CErc20Delegate.sol:CErc20Delegate"].abi
    )
  );
  cErc20 = await cErc20
    .deploy({
      data:
        "0x" +
        fuse.compoundContracts["contracts/CErc20Delegate.sol:CErc20Delegate"]
          .bin,
    })
    .send({ from: selectedAccount });

  var cToken = new web3.eth.Contract(
    JSON.parse(
      fuse.compoundContracts["contracts/CEtherDelegate.sol:CEtherDelegate"].abi
    )
  );
  cToken = await cToken
    .deploy({
      data:
        "0x" +
        fuse.compoundContracts["contracts/CEtherDelegate.sol:CEtherDelegate"]
          .bin,
    })
    .send({ from: selectedAccount });
}

async function deposit(cToken, underlying, amount, depositor) {
  var underlyingToken = new this.web3.eth.Contract(
    JSON.parse(
      fuse.compoundContracts["contracts/EIP20Interface.sol:EIP20Interface"].abi
    ),
    underlying
  );

  var cTokenContract = new this.web3.eth.Contract(
    JSON.parse(
      fuse.compoundContracts["contracts/CErc20Delegate.sol:CErc20Delegate"].abi
    ),
    cToken
  );

  await underlyingToken.methods.approve(cToken, amount.mul(web3.utils.toBN(2))).send({from: depositor});
  await cTokenContract.methods.mint(amount).send({from: depositor});
}

async function deployFusePool() {
  const [fusePool] = await fuse.deployPool(
    "Tanks",
    false,
    web3.utils.toBN(0.5e18),
    web3.utils.toBN(20e18),
    web3.utils.toBN(1.08e18),
    "PreferredPriceOracle",
    {isPrivate: false},
    { from: selectedAccount }
  );

  const [fDAI] = await fuse.deployAsset(
    {
      underlying: dai,
      decimals: 8,
      comptroller: fusePool,
      initialExchangeRateMantissa: web3.utils.toBN(1e18),
      name: "Tanks DAI",
      symbol: "f-1-DAI",
      interestRateModel: "JumpRateModel",
      admin: selectedAccount,
    },
    web3.utils.toBN(0.75e18),
    web3.utils.toBN(0.2e18),
    web3.utils.toBN(0),
    { from: selectedAccount },
    true
  );

  const [fToken] = await fuse.deployAsset(
    {
      underlying: token,
      decimals: 8,
      comptroller: fusePool,
      initialExchangeRateMantissa: web3.utils.toBN(1e18),
      name: `Tanks ${addresses.TOKEN_SYMBOL}`,
      symbol: "f-1-WBTC",
      interestRateModel: "JumpRateModel",
      admin: selectedAccount,
    },
    web3.utils.toBN(0.75e18),
    web3.utils.toBN(0.2e18),
    web3.utils.toBN(0),
    { from: selectedAccount },
    true
  );

  deposit(fDAI, dai, web3.utils.toBN("1000000000000000000000000"), daiHolder);

  return [fusePool];
}

async function deploy() {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [tokenHolder],
  });
  await deployFuse();
  const [comptroller] = await deployFusePool();
  const [rebalancer] = await web3.eth.getAccounts();

  const RariTankFactory = await ethers.getContractFactory("RariTankFactory");
  const RariTankDelegate = await ethers.getContractFactory("RariTankDelegate");
  const Keeper = await ethers.getContractFactory("Keeper");

  const tankDelegate = await RariTankDelegate.deploy();
  await tankDelegate.deployed();

  const rariTankFactory = await RariTankFactory.deploy(
    Fuse.FUSE_POOL_DIRECTORY_CONTRACT_ADDRESS,
    rebalancer,
  );

  await rariTankFactory.deployed();

  // Add the tank factory as a Keep3r job
  const governance = await ethers.provider.getSigner(addresses.KEEP3R_GOVERNANCE);
  const keep3r = await ethers.getContractAt(Keep3rABI, addresses.KEEP3R);

  keep3r.connect(governance).addJob(rariTankFactory.address);

  await rariTankFactory.deployTank(token, comptroller, tankDelegate.address);
  const tank = await rariTankFactory.getTankByImplementation(token, tankDelegate.address);

  //const keeper = await Keeper.deploy(rariTankFactory.address);
  
  // await hre.network.provider.request({
  //   method: "evm_increaseTime",
  //   params: [3000000000],
  // }); 

  // await keeper.activate();

  const oracle = await ethers.getContractAt(
    Keep3rOracleABI,
    addresses.KEEP3R_ORACLE
  );

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [addresses.ORACLE_BOT],
  });

  const bot = await ethers.provider.getSigner(addresses.ORACLE_BOT);
  oracle.connect(bot).update(
    "0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44",
    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
  );
  
  console.log(`USING ${addresses.TOKEN_SYMBOL}`);

  return [rariTankFactory, tank, bot];
}

module.exports = deploy();
