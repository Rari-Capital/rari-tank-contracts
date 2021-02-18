const hre = require("hardhat");
const ethers = hre.ethers;

const chai = require("chai");
const chaiBnEqual = require("chai-bn-equal");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiBnEqual);
chai.use(chaiAsPromised);
chai.should();

const contracts = require("./helpers/deploy");
const external = require("./helpers/contracts");

const x = require("./fuse-sdk");

//const rariFundManager, rariTankFactory, rariDataProvider;

describe("RariFundManager", async () => {
    before(async () => {
        [rariFundManager, rariTankFactory, rariDataProvider] = await contracts;
    });

    describe("Deposits function correctly", async () => {
        it("Sends funds to the tank", async () => {
            
        });
    })
})