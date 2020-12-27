import { Func } from "mocha";

const hre = require("hardhat");
const ethers = hre.ethers;

const tokens: Array<String> = require("./helpers/tokens");
const contracts = require("./helpers/contracts");

async function deploy() {
  const [owner, rebalancer] = await ethers.getSigners();

  //prettier-ignore
  const RariFundManager = await ethers.getContractFactory("RariFundManager");
  //prettier-ignore
  const RariFundController = await ethers.getContractFactory("RariFundController");

  const rariFundManager = await RariFundManager.deploy();
  await rariFundManager.deployed();

  const rariFundController = await RariFundController.deploy(
    rariFundManager.address,
    rebalancer.address,
    contracts.comptroller,
    contracts.priceFeed
  );
  await rariFundController.deployed();
  rariFundManager.setRariFundController(rariFundController.address);

  console.log(await rariFundController.owner());
  console.log(owner.address);

  for (let i = 0; i < tokens.length; i++) {
    await rariFundController
      .newTank(tokens[i])
      .catch((error: any) => console.log(error));
  }
}

deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });
