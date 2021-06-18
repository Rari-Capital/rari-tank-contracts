const hre = require("hardhat");
const ethers = hre.ethers;

import deploy from "./helpers/deploy";

const { expect } = require("chai");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    await deploy();
  });
});
