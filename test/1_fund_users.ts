import { ethers } from "ethers";

const chai = require("chai");
const hre = require("hardhat");

const chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);
chai.should();

let rariFundManager: any;

describe("RariFundManager", async () => {
  beforeEach(async () => {
    const RariFundManager = await hre.ethers.getContractFactory(
      "RariFundManager"
    );
    rariFundManager = await RariFundManager.deploy();
    await rariFundManager.deployed();

    console.log(rariFundManager.address);
  });

  it("Reverts if the currency is not supported", async () => {
    await rariFundManager.deposit("NONE", 50).should.be.rejectedWith("revert");
  });
});
