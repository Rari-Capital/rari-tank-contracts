pragma solidity ^0.7.0;

import "./lib/CompoundPoolController.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract RariFundTank is Ownable {
    using SafeMath for uint256;
    using CompoundPoolController for address;

    ///@dev The address of the ERC20Token supported by the tank
    address private supportedToken;

    ///@dev The decimal precision of the supportedToken
    uint256 private decimals;

    ///@dev Compound's Comptroller Contract
    address private comptroller;

    ///@dev Compound's Pricefeed program
    address private priceFeed;

    ///@dev Maps user addresses to their cToken balances
    mapping(address => uint256) private cTokenBalances;

    constructor(
        address _supportedToken,
        uint256 _decimals,
        address _comptroller,
        address _priceFeed
    ) Ownable() {
        supportedToken = _supportedToken;
        decimals = _decimals;
        comptroller = _comptroller;
        priceFeed = _priceFeed;
    }

    ///@dev An array of addresses whose funds have yet to be converted to cTokens
    address[] private unusedDeposits;

    ///@dev The version number of the data
    uint256 private dataVersionNumber;

    ///@dev Maps addresses to the amount of unused funds they have deposited
    mapping(uint256 => mapping(address => uint256)) private unusedDepositBalances;

    ///@dev The total unused token balance
    uint256 public totalUnusedBalance;

    /**
        @dev Deposit funds into the tank
        @param account The address of the depositing user
        @param amount The amount being deposited
    */
    function deposit(address account, uint256 amount) external onlyOwner() {
        require(
            supportedToken.getPrice(amount, priceFeed) >= 500,
            "RariFundTank: Deposit amount must be over 500 dollars"
        );

        bytes32 key = keccak256(abi.encode(account, dataVersionNumber));
        //prettier-ignore
        if (unusedDepositBalances[dataVersionNumber][account] == 0) unusedDeposits.push(account);
        unusedDepositBalances[dataVersionNumber][account] += amount;
        totalUnusedBalance += amount;
    }

    /**
        @dev Deposits unused funds into Compound and borrows another asset
        @param erc20Contract The address of the ERC20 Contract to be borrowed (usually USDC)
    */
    function depositFunds(address erc20Contract) external onlyOwner() {
        require(totalUnusedBalance > 0, "RariFundTank: No dormant funds available");
        // Calculate the cToken balance for each user
        for (uint256 i = 0; i < unusedDeposits.length; i++) {
            address account = unusedDeposits[i];

            //prettier-ignore
            uint256 deposited = unusedDepositBalances[dataVersionNumber][account];
            cTokenBalances[account] += supportedToken.getUnderlyingToCTokens(deposited);
        }
        // Deposit the total unused balance into Compound
        supportedToken.deposit(totalUnusedBalance, comptroller); // Deposit all of the unused funds into Compound

        // Calculate the total borrow amount
        //prettier-ignore
        uint256 usdBorrowAmount = comptroller.getMaxUSDBorrowAmount();
        //prettier-ignore
        uint256 borrowAmount = erc20Contract.calculateMaxBorrowAmount(usdBorrowAmount, priceFeed).div(2);
        uint256 borrowBalance = erc20Contract.borrowBalanceCurrent();

        //prettier-ignore
        if (borrowAmount > borrowBalance) erc20Contract.borrow(borrowAmount - borrowBalance);
        else if(borrowBalance > borrowAmount) erc20Contract.repayBorrow(borrowBalance - borrowAmount);

        delete unusedDeposits;
        delete totalUnusedBalance;
        dataVersionNumber++;
    }
}
