/*
 * Tests for the TankFactory
 */

import deploy, { deployTank, encodeArgs } from "./helpers/utils";
import { Contract } from "@ethersproject/contracts";

import chai, { expect } from "chai";
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);
chai.should();

import addresses from "./helpers/constants";
const borrowing = addresses.BORROWING;

describe("TankFactory", async function () {
  let factory: Contract, tank: Contract;
  this.timeout(300000); // Set new timeout

  before(async () => {
    [factory, tank] = await deploy(); // Deploy contracts and get addresses
  });

  describe("Tank deployments", async () => {
    it("Registers new implementation", async () => {
      factory.newImplementation(addresses.EXAMPLE_ADDRESS);
      expect((await factory.initialImplementations(1)).toLowerCase()).to.equal(
        addresses.EXAMPLE_ADDRESS.toLowerCase()
      );
    });

    it("Allows you to deploy new Tank", async () => {
      const parameters: String = await encodeArgs(
        ["address", "address"],
        [borrowing.ADDRESS, addresses.FUSE_COMPTROLLER]
      );

      await deployTank(factory, 1, parameters); // Deploy a Tank that uses DAI as collateral
    });
  });

  describe("Security", async () => {
    //We need a better name
    it("Does not allow you to deploy a Tank with the same input", async () => {
      const parameters: String = await encodeArgs(
        ["address", "address"],
        [borrowing.ADDRESS, addresses.FUSE_COMPTROLLER]
      );

      await deployTank(factory, 1, parameters).should.be.revertedWith("revert");
    });

    it("Requires valid comptroller", async () => {
      const parameters: String = await encodeArgs(
        ["address", "address"],
        [borrowing.ADDRESS, addresses.EXAMPLE_ADDRESS] // Example Address is not a Comptroller
      );

      await deployTank(factory, 1, parameters).should.be.revertedWith("revert");
    });
  });
});
