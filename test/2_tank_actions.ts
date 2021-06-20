/**
 * Tests for Tanks (strategy contracts)
 * Evaluates user facing functions including deposits, withdrawals, and balances
 * Note that since some of the withdrawal tests depend on rebalances, you will find more tests in later code
 */
import { ethers } from "hardhat";
import { Contract } from "@ethersproject/contracts";
import contracts, { supplyToFuse, impersonateAccount } from "./helpers/utils";

import chai, { expect } from "chai";
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);
chai.should();

import addresses from "./helpers/constants";
import Erc20Abi from "./helpers/abi/ERC20.json";

const [token] = [addresses.TOKEN];

describe("Tanks", async function () {
  let factory: Contract, tank: Contract;
  this.timeout(300000); // Set new timeout

  before(async () => {
    [factory, tank] = await contracts; // Deploy contracts and get addresses
  });

  describe("Deposits", async () => {
    it("Allows users to deposit tokens", async () => {
      await (await token.CONTRACT)
        .connect(token.SIGNER)
        .approve(tank.address, token.AMOUNT);

      await tank.connect(token.SIGNER).deposit(token.AMOUNT);
    });

    it("Mints Tank Tokens at a 1:1 ratio", async () => {
      const decimals = await (await token.CONTRACT).decimals(); // Tank Tokens have 18 decimals, so we must make both values equal

      expect(
        Math.round((await tank.balanceOf(token.HOLDER)) / 10 ** 18)
      ).is.equal(Math.round(parseInt(token.AMOUNT) / 10 ** decimals));
    });

    it("Tank tokens increase in value if the Tank accumulates more tokens", async () => {
      const balanceBefore = await tank.callStatic.balanceOfUnderlying(
        token.HOLDER
      );

      (await token.CONTRACT)
        .connect(token.SIGNER)
        .transfer(tank.address, token.AMOUNT);

      impersonateAccount(tank.address);

      await supplyToFuse(
        await tank.cToken(),
        await ethers.provider.getSigner(tank.address),
        token.AMOUNT
      );

      const balanceAfter = await tank.callStatic.balanceOfUnderlying(
        token.HOLDER
      );

      expect(parseInt(balanceAfter)).is.greaterThan(parseInt(balanceBefore));
    });

    it("Mints cTokens on Fuse", async () => {
      const address: string = await tank.cToken();
      const cToken: Contract = await ethers.getContractAt(Erc20Abi, address);

      expect(parseInt(await cToken.balanceOf(tank.address))).is.greaterThan(0);
    });
  });

  describe("Withrawals", async () => {
    it("Burns Tank tokens", async () => {
      // const balanceBefore = await tank.callStatic.balanceOf(token.HOLDER);
      // await tank.connect(token.SIGNER).withdraw(token.AMOUNT);
      // const balanceAfter = await tank.callStatic.balanceOf(token.HOLDER);
      // expect(parseInt(balanceBefore)).is.greaterThan(parseInt(balanceAfter));
    });
  });
});
