import addresses from "./constants";
import hre, { ethers } from "hardhat";
import { Contract, ContractFactory } from "@ethersproject/contracts";

import Erc20Abi from "./abi/ERC20.json";
import FactoryAbi from "./abi/Factory.json";
import TankAbi from "./abi/RariFundTank.json";

const dai = addresses.DAI;
const token = addresses.TOKEN;

export default async function deploy(): Promise<Contract[]> {
  await impersonateAccounts();

  const implementation = await deployContract("Tank", []);
  const factoryDelegate = await deployContract("TankFactory", []);
  const factoryDelegator = await deployContract("FactoryDelegator", [
    factoryDelegate.address,
  ]);

  const factory = await ethers.getContractAt(
    FactoryAbi,
    factoryDelegate.address
  );

  await factory.newImplementation(implementation.address);

  const parameters = await encodeArgs(
    ["address", "address"],
    [token.ADDRESS, addresses.FUSE_COMPTROLLER]
  );

  //await factory.deployTank(1, `0x${parameters}`);
  const tank = await deployTank(factory, 1, parameters);
  return [factory, tank];
}

async function impersonateAccounts() {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [dai.HOLDER],
  });

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [token.HOLDER],
  });
}

async function deployContract(name: string, args: any): Promise<Contract> {
  const factory = await ethers.getContractFactory(name);
  const contract = await factory.deploy(...args);
  await contract.deployed();

  return contract;
}

async function deployTank(
  factory: Contract,
  implementation: Number,
  parameters: String
): Promise<Contract> {
  await factory.deployTank(implementation, `0x${parameters}`);
  const tanks = await factory.getTanks();
  const tank = tanks[tanks.length - 1];

  return ethers.getContractAt(TankAbi, tank);
}

async function encodeArgs(types: string[], values: any[]) {
  const abiCoder = new ethers.utils.AbiCoder();

  return abiCoder.encode(types, values).replace(/^(0x)/, "");
}
