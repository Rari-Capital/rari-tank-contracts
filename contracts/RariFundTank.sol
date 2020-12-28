pragma solidity ^0.7.0;

import "./lib/CompoundPoolController.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract RariFundTank is Ownable {
    using CompoundPoolController for address;
    using SafeERC20 for IERC20;

    ///@dev The address of the ERC20Token supported by the tank
    address private erc20Contract;

    ///@dev Compound's Comptroller Contract
    address private comptroller;

    ///@dev Compound's Pricefeed program
    address private priceFeed;

    ///@dev Maps user addresses to their cToken balances
    mapping(address => uint256) private cTokenBalances;

    constructor(
        address _erc20Contract,
        address _comptroller,
        address _priceFeed
    ) Ownable() {
        erc20Contract = _erc20Contract;
        comptroller = _comptroller;
        address _priceFeed = priceFeed;
    }

    ///@dev An array of addresses whose funds have yet to be converted to cTokens
    address[] private unusedDeposits;

    ///@dev The version number of the data
    uint256 private dataVersionNumber;

    ///@dev Maps addresses to the amount of unused funds they have deposited
    mapping(bytes32 => uint256) private unusedDepositBalances;

    ///@dev The total unused token balance
    uint256 public totalUnusedBalance;

    function deposit(address account, uint256 amount) external onlyOwner() {
        bytes32 key = keccak256(abi.encode(account, dataVersionNumber));
        if (unusedDepositBalances[key] == 0) unusedDeposits.push(account);
        unusedDepositBalances[key] += amount;
        totalUnusedBalance += amount;
    }
}
