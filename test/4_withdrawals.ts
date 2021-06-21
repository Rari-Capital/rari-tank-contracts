/**
 * Test the withdrawal functionality for tokens
 */

import { ethers } from "hardhat";
import addresses from "./helpers/constants";
import contracts from "./helpers/utils";
const [token, borrowing] = [addresses.TOKEN, addresses.BORROWING];

import { Contract } from "@ethersproject/contracts";
import { BigNumber } from "@ethersproject/bignumber";

import chai, { expect } from "chai";
const chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);
chai.should();

describe("Withdrawals", async function () {
  let factory: Contract, tank: Contract;
  let balance: BigNumber, underlyingBalance: number, tankBalance;
  this.timeout(300000); // Set new timeout

  before(async () => {
    [factory, tank] = await contracts; // Deploy contracts and get addresses9

    balance = await (await token.CONTRACT).balanceOf(token.HOLDER);
    underlyingBalance = await tank.callStatic.balanceOfUnderlying(token.HOLDER);
  });

  describe("Withdrawals", async () => {
    it("Burns Tank tokens", async () => {
      const balanceBefore = await tank.callStatic.balanceOf(token.HOLDER);
      await tank.connect(token.SIGNER).withdraw(token.AMOUNT);
      expect(parseInt(balanceBefore)).is.greaterThan(
        parseInt(await tank.callStatic.balanceOf(token.HOLDER))
      );
    });

    it("Gets sent exact amount of tokens requested", async () => {
      const newBalance: BigNumber = await (await token.CONTRACT).balanceOf(
        token.HOLDER
      );
      expect(newBalance.sub(balance)).is.equal(token.AMOUNT);
    });
  });

  describe("Security", async () => {
    it("Reverts if amount is too high", async () => {
      const balance: number = await tank.callStatic.balanceOfUnderlying(
        token.HOLDER
      );

      await tank
        .connect(token.SIGNER)
        .withdraw(balance + 1)
        .should.be.revertedWith(
          "revert Tank: Amount must be less than balance"
        );
    });
  });
});
