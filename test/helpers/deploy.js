const contracts = require("./constants");
const hre = require("hardhat");
const ethers = hre.ethers;
const web3 = hre.web3;

const prompt = require('prompt-sync')();
const Fuse = require("./fuse-sdk/src/index");
const fuse = new Fuse(web3.currentProvider);

const addresses = require("./constants");
const selectedAccount = addresses.FUSE_DEPLOYER;
const [usdc, wbtc] = [addresses.USDC, addresses.WBTC, addresses.USDC_HOLDER];
const [usdcHolder, wbtcHolder] = [addresses.USDC_HOLDER, addresses.WBTC_HOLDER];

const Keep3rABI = require("../abi/Keep3r.json")


async function deployFuse() {
  const preferredPriceOracle = await fuse.deployPriceOracle(
    "PreferredPriceOracle",
    { isPublic: true },
    { from: selectedAccount }
  );
  console.log(preferredPriceOracle, "PREFERRED PRICE ORACLE ADDRESS");

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
  console.log(comptroller.options.address, "COMPTROLLER ADDRESS");

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
  console.log(cErc20.options.address, "CERC20 ADDRESS");

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
  console.log(cToken.options.address, "CETH ADDRESS");
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

  console.log(await underlyingToken.methods.balanceOf(cToken).call(), "CTOKEN BALANCE");
  console.log(await cTokenContract.methods.totalSupply().call(), "CTOKEN TOTAL SUPPLY");
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
  console.log(fusePool, "FUSEPOOL ADDRESS");

  const [fUSDC] = await fuse.deployAsset(
    {
      underlying: usdc,
      decimals: 8,
      comptroller: fusePool,
      initialExchangeRateMantissa: web3.utils.toBN(1e18),
      name: "Tanks USDC",
      symbol: "f-1-USDC",
      interestRateModel: "JumpRateModel",
      admin: selectedAccount,
    },
    web3.utils.toBN(0.75e18),
    web3.utils.toBN(0.2e18),
    web3.utils.toBN(0),
    { from: selectedAccount },
    true
  );

  const [fWBTC] = await fuse.deployAsset(
    {
      underlying: wbtc,
      decimals: 8,
      comptroller: fusePool,
      initialExchangeRateMantissa: web3.utils.toBN(1e18),
      name: "Tanks WBTC",
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

  console.log(fUSDC, "fUSDC ADDRESS");
  console.log(fWBTC, "fWBTC ADDRESS");

  deposit(fUSDC, usdc, web3.utils.toBN(1e12), usdcHolder);
  deposit(fWBTC, wbtc, web3.utils.toBN(1e8), wbtcHolder);

  return [fusePool];
}

async function deploy() {
  await deployFuse();
  const [comptroller] = await deployFusePool();
  const [rebalancer] = await web3.eth.getAccounts();

  const RariDataProvider = await ethers.getContractFactory("RariDataProvider");
  const RariTankFactory = await ethers.getContractFactory("RariTankFactory");
  const RariTankDelegate = await ethers.getContractFactory("RariTankDelegate");

  const tankDelegate = await RariTankDelegate.deploy();
  await tankDelegate.deployed();
  console.log(tankDelegate.address, "TANK_DELEGATE ADDRESS");

  const rariDataProvider = await RariDataProvider.deploy();
  await rariDataProvider.deployed();
  console.log(rariDataProvider.address, "DATA PROVIDER ADDRESS");

  const rariTankFactory = await RariTankFactory.deploy(
    rariDataProvider.address,
    Fuse.FUSE_POOL_DIRECTORY_CONTRACT_ADDRESS,
    rebalancer,
  );

  await rariTankFactory.deployed();
  console.log(rariTankFactory.address, "FACTORY ADDRESS");

  // Add the tank factory as a Keep3r job
  const governance = await ethers.provider.getSigner(addresses.KEEP3R_GOVERNANCE);
  const keep3r = await ethers.getContractAt(Keep3rABI, addresses.KEEP3R);

  keep3r.connect(governance).addJob(rariTankFactory.address);

  await rariTankFactory.deployTank(wbtc, comptroller, tankDelegate.address);
  console.log("deployed");
  const tank = await rariTankFactory.getTankByImplementation(wbtc, tankDelegate.address)
  console.log(tank, "TANK ADDRESS");

  return [rariTankFactory, rariDataProvider, tank];
}

module.exports = deploy();
