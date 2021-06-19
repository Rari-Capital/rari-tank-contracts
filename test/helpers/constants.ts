import { ethers } from "hardhat";
import Erc20Abi from "./abi/ERC20.json";

const tokens = [
  {
    symbol: "WBTC",
    address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    holder: "0x0C4809bE72F9E117D75381438c5dAeC8AbE75BaD",
    depositAmount: "100000000",
    withdrawalAmount: "100000500",
    largeWithdrawalAmount: "200000500",
    useWeth: false,
  },
  {
    symbol: "USDC",
    address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    holder: "0x55FE002aefF02F77364de339a1292923A15844B8",
    depositAmount: "50000000000",
    withdrawalAmount: "50500000000",
    largeWithdrawalAmount: "100000000000",
    useWeth: false,
  },
  {
    symbol: "RGT",
    address: "0xD291E7a03283640FDc51b121aC401383A46cC623",
    holder: "0xC1d1B12bCE4a73310F268d49EFAB95eb2A679609",
    depositAmount: "4500000000000000000000",
    withdrawalAmount: "4505000000000000000000",
    largeWithdrawalAmount: "9000000000000000000000",
    useWeth: true,
  },
  {
    symbol: "SUSHI",
    address: "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2",
    holder: "0x5028D77B91a3754fb38B2FBB726AF02d1FE44Db6",
    depositAmount: "4500000000000000000000",
    withdrawalAmount: "4505000000000000000000",
    largeWithdrawalAmount: "9000000000000000000000",
    useWeth: true,
  },
];

const token = tokens[Math.floor(Math.random() * tokens.length)];

export default {
  TOKEN: {
    CONTRACT: ethers.getContractAt(Erc20Abi, token.address),
    ADDRESS: token.address,
    SYMBOL: token.symbol,
    SIGNER: ethers.provider.getSigner(token.holder),
    HOLDER: token.holder,
    AMOUNT: token.depositAmount,
    WITHDRAWAL_AMOUNT: token.withdrawalAmount,
    LARGE_WITHDRAWAL_AMOUNT: token.largeWithdrawalAmount,
    USE_WETH: token.useWeth,
  },

  BORROWING: {
    ADDRESS: "0x6b175474e89094c44da98b954eedeac495271d0f",
    HOLDER: "0x01Ec5e7e03e2835bB2d1aE8D2edDEd298780129c",
    HOLDER_SIGNER: ethers.provider.getSigner(
      "0x01Ec5e7e03e2835bB2d1aE8D2edDEd298780129c"
    ),
    CONTRACT: ethers.getContractAt(
      Erc20Abi,
      "0x6b175474e89094c44da98b954eedeac495271d0f"
    ),
  },

  RSPT: "0x0833cfcb11A5ba89FbAF73a407831c98aD2D7648",
  RARI_FUND_CONTROLLER: "0xd7590e93a2e04110ad50ec70eade7490f7b8228a",

  FUSE_COMPTROLLER: "0x6E7fb6c5865e8533D5ED31b6d43fD95f4C411834",
  FUSE_POOL_DIRECTORY: "0x835482FE0532f169024d5E9410199369aAD5C77E",

  KEEP3R: "0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44",
  KEEP3R_GOVERNANCE: "0x2d407ddb06311396fe14d4b49da5f0471447d45c",

  CHAINLINK_ORACLE: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
  ROUTER: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",

  ORACLE_BOT: "0x9f6FdC2565CfC9ab8E184753bafc8e94C0F985a0",
  KEEP3R_ORACLE: "0x73353801921417F465377c8d898c6f4C0270282C",

  FUSE_DEPLOYER: "0xf977814e90da44bfa03b6295a0616a897441acec",
  FUSE_DEPLOYER_SECONDARY: "0x1Eeb75CFad36EDb6C996f7809f30952B0CA0B5B9",

  EXAMPLE_ADDRESS: "0x8888801af4d980682e47f1a9036e589479e835c5", // MPH Token
  EXAMPLE_COMPTROLLER: "",
};
