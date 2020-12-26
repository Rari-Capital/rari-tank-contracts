const hre = require("hardhat");

async function deploy() {
  //prettier-ignore
  const RariFundManager = await hre.ethers.getContractFactory("RariFundManager");
  //prettier-ignore
  const RariFundController = await hre.ethers.getContractFactory("RariFundController");

  const rariFundManager = await RariFundManager.deploy();
  await rariFundManager.deployed();

  //prettier-ignore
  const rariFundController = await RariFundController.deploy(rariFundManager.address);
  await rariFundController.deployed;

  rariFundManager.setRariFundController(RariFundController.address);
}

deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });
