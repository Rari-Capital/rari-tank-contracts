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
    contracts.priceFeed,
    contracts.rariFundManager
  );
  await rariFundController.deployed();

  await rariFundManager.setRariFundController(rariFundController.address);

  for (let i = 0; i < tokens.length; i++) {
    await rariFundController
      .newTank(tokens[i].token, tokens[i].decimals)
      .catch((error) => console.log(error));
  }
}

module.exports = deploy;
