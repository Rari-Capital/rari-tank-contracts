/**
 * Tests for Tank rebalances
 */

import hre, { ethers } from "hardhat";
import addresses from "./helpers/constants";
import contracts, { impersonateAccount, advanceBlock } from "./helpers/utils";
const [token, borrowing] = [addresses.TOKEN, addresses.BORROWING];

import { Contract } from "@ethersproject/contracts";
import { expect } from "chai";

import Erc20Abi from "./helpers/abi/ERC20.json";
import CErc20Abi from "./helpers/abi/CERC20.json";
import { BigNumber } from "@ethersproject/bignumber";

describe("Rebalances", async function () {
  let factory: Contract, tank: Contract;
  this.timeout(300000); // Set new timeout

  before(async () => {
    [factory, tank] = await contracts; // Deploy contracts and get addresses
  });

  describe("Correctly function", async () => {
    it("Rebalances do not fail", async () => {
      await hre.network.provider.send("evm_setNextBlockTimestamp", [1616915378]);
      await tank.rebalance(token.USE_WETH);
    });

    it("Rebalancers are paid", async () => {
      const rebalancer = (await ethers.getSigners())[0];
      expect(parseInt(await (await token.CONTRACT).balanceOf(rebalancer.address))).is.greaterThan(
        0
      );
    });
  });

  describe("External Interactions", async () => {
    it("Deposits into the Yield Source", async () => {
      const yieldSourceToken = await ethers.getContractAt(Erc20Abi, addresses.RSPT);
      expect(parseInt(await yieldSourceToken.balanceOf(tank.address))).is.greaterThan(0);
    });

    it("Earning DAI increases the exchangeRate and user balances", async () => {
      await advanceBlock(100);

      await (await borrowing.CONTRACT)
        .connect(borrowing.HOLDER_SIGNER)
        .transfer(addresses.RARI_FUND_CONTROLLER, borrowing.AMOUNT);

      const balance = await tank.callStatic.balanceOfUnderlying(token.HOLDER);
      await tank.rebalance(token.USE_WETH);
      expect(parseInt(balance.toString())).is.lessThan(
        parseInt((await tank.callStatic.balanceOfUnderlying(token.HOLDER)).toString())
      );
    });
  });

  describe("Registers profit", async () => {
    it("Repays funds", async () => {
      await advanceBlock(100);

      await impersonateAccount(tank.address);
      const tankSigner = await ethers.provider.getSigner(tank.address);
      const cToken = await ethers.getContractAt(CErc20Abi, await tank.cToken());

      const balance: BigNumber = await cToken.callStatic.balanceOfUnderlying(tank.address);

      await cToken.connect(tankSigner).redeemUnderlying(balance.div(2));

      await (await borrowing.CONTRACT)
        .connect(borrowing.HOLDER_SIGNER)
        .transfer(addresses.RARI_FUND_CONTROLLER, borrowing.AMOUNT);

      await tank.rebalance(token.USE_WETH);
    });
  });
});
