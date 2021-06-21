/**
 * Tests for Tank rebalances
 */

import { ethers } from "hardhat";
import addresses from "./helpers/constants";
import contracts from "./helpers/utils";
const [token, borrowing] = [addresses.TOKEN, addresses.BORROWING];

import { Contract } from "@ethersproject/contracts";
import { expect } from "chai";

import Erc20Abi from "./helpers/abi/ERC20.json";

describe("Rebalances", async function () {
  let factory: Contract, tank: Contract;
  this.timeout(300000); // Set new timeout

  before(async () => {
    [factory, tank] = await contracts; // Deploy contracts and get addresses
  });

  describe("External Interactions", async () => {
    it("Rebalances function correctly", async () => {
      await tank.rebalance(token.USE_WETH);
    });

    it("Deposits into the Yield Source", async () => {
      const yieldSourceToken = await ethers.getContractAt(
        Erc20Abi,
        addresses.RSPT
      );
      expect(
        parseInt(await yieldSourceToken.balanceOf(tank.address))
      ).is.greaterThan(0);
    });
  });

  describe("Registers profit", async () => {
    it("Earning DAI increases the exchangeRate and user balances", async () => {
      await (await borrowing.CONTRACT)
        .connect(borrowing.HOLDER_SIGNER)
        .transfer(addresses.RARI_FUND_CONTROLLER, borrowing.AMOUNT);

      const balance = await tank.callStatic.balanceOfUnderlying(token.HOLDER);
      await tank.rebalance(token.USE_WETH);
      expect(parseInt(balance.toString())).is.lessThan(
        parseInt(
          (await tank.callStatic.balanceOfUnderlying(token.HOLDER)).toString()
        )
      );
    });
  });
});
