const contracts = require("./contracts");
const ethers = hre.ethers;


async function deploy() {
    const RariFundManager = await ethers.getContractFactory("RariFundManager");
    const RariDataProvider = await ethers.getContractFactory("RariDataProvider");
    const RariTankFactory = await ethers.getContractFactory("RariTankFactory");

    const rariDataProvider = await RariDataProvider.deploy();
    console.log("leebs")
    await rariDataProvider.deployed();
    console.log("sheebs")
    console.log(rariDataProvider.address)

    const rariFundManager = await RariFundManager.deploy();
    await rariFundManager.deployed();
    console.log(rariFundManager.address);

    const rariTankFactory = await RariTankFactory.deploy(rariFundManager.address, rariDataProvider.address);
    await rariTankFactory.deployed();
    console.log(rariTankFactory.address);

    rariFundManager.setFactory(rariTankFactory.address);
    rariFundManager.deployTank(contracts.token, contracts.cErc20, contracts.borrowCErc20, contracts.comptroller);

    const rariFundTankContract = await rariFundManager.getTank(contracts.token);

    console.log(rariFundTankContract);

    return( 
    [
        rariFundManager,
        rariTankFactory,
        rariDataProvider,
        rariFundTankContract,
        contracts.token,
    ])
}

module.exports = deploy();