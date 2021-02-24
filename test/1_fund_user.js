const hre = require("hardhat");
const ethers = hre.ethers;

const chai = require("chai");
const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const contracts = require("./helpers/deploy");
const constants = require("./helpers/constants");


//const rariFundManager, rariTankFactory, rariDataProvider;

describe("RariFundManager", async function() {
    this.timeout(300000)
    before(async () => {
        [rariFundManager, rariTankFactory, rariDataProvider] = await contracts;
    })

    describe("Deposits function correctly", async () => {
        it("Sends funds to the tank", async () => {
        });
    })
})