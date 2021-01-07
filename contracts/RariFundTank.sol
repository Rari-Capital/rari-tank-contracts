pragma solidity ^0.7.0;

import "./lib/CompoundPoolController.sol";
import "./lib/RariPoolController.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract RariFundTank is Ownable {
    using SafeMath for uint256;
    //using RariPoolController for address;
    //using CompoundPoolController for address;

    ///@dev The address of the ERC20Token supported by the tank
    address private supportedToken;

    ///@dev The decimal precision of the supportedToken
    uint256 private decimals;

    ///@dev Compound's Comptroller Contract
    address private comptroller;

    ///@dev Compound's Pricefeed program
    address private priceFeed;

    ///@dev The address of the Rari Stable Pool Fund Manager
    address private rariStablePool;

    ///@dev The total cToken balance
    uint256 private totalCTokenBalance;

    ///@dev An array of addresses who have deposited and have a balance of more than 0 cToken
    address[] private deposited;

    ///@dev Maps an address to a boolean indicated whether or not they have previously deposited
    mapping(address => bool) private previouslyDeposited;

    ///@dev Maps user addresses to their cToken balances
    mapping(address => uint256) private cTokenBalances;

    constructor(
        address _supportedToken,
        uint256 _decimals,
        address _comptroller,
        address _priceFeed,
        address _rariStablePool
    ) Ownable() {
        supportedToken = _supportedToken;
        decimals = _decimals;
        comptroller = _comptroller;
        priceFeed = _priceFeed;
        rariStablePool = _rariStablePool;
    }

    ///@dev An array of addresses whose funds have yet to be converted to cTokens
    address[] private unusedDeposits;

    ///@dev The version number of the data
    uint256 private dataVersionNumber;

    ///@dev Maps addresses to the amount of unused funds they have deposited
    mapping(uint256 => mapping(address => uint256)) private unusedDepositBalances;

    ///@dev The total unused token balance
    uint256 private totalUnusedBalance;

    ///@dev The tank's balance within the stable pool
    uint256 private stablePoolBalance;

    ///@dev Maps user addresses to their profits from the the Rari Stable Pool in USD
    mapping(address => uint256) private usdProfit;

    /**
        @dev Deposit funds into the tank
        @param account The address of the depositing user
        @param amount The amount being deposited
    */
    function deposit(address account, uint256 amount) external onlyOwner() {
        require(
            CompoundPoolController.getPrice(supportedToken, amount, priceFeed) >= 500,
            "RariFundTank: Deposit amount must be over 500 dollars"
        );

        //prettier-ignore
        if (unusedDepositBalances[dataVersionNumber][account] == 0) unusedDeposits.push(account);
        unusedDepositBalances[dataVersionNumber][account] += amount;
        totalUnusedBalance += amount;
    }

    /**
        @dev Deposits unused funds into Compound and borrows another asset
        @param erc20Contract The address of the ERC20 Contract to be borrowed (usually USDC)
    */
    function rebalance(address erc20Contract, string memory currencyCode)
        external
        onlyOwner()
    {
        //uint256 profit = rariStablePool.getUSDBalance().sub(stablePoolBalance);
        //split(profit);
        if (totalUnusedBalance > 0) depositUnusedFunds(erc20Contract, currencyCode);

        delete unusedDeposits;
        delete totalUnusedBalance;
        dataVersionNumber++;
    }

    /**
        @dev Given a certain USD gain from the pool, split it among all of the depositors
        @param amount The amount to split
    */
    function split(uint256 amount) private {
        //gas saving
        uint256 totalBalance = totalCTokenBalance;

        for (uint256 i = 0; i < deposited.length; i++) {
            address account = deposited[i];
            uint256 balance = cTokenBalances[account];

            uint256 balanceFactor = balance.mul(1e18).div(totalBalance);
            uint256 profit = balanceFactor.mul(amount).div(1e18);

            usdProfit[account] += profit;
        }
    }

    /**
        @dev Deposit unused funds into the tanks
        @param erc20Contract The address of the ERC20 Contract to be borrowed (usually USDC)
    */
    function depositUnusedFunds(address erc20Contract, string memory currencyCode)
        private
    {
        // Calculate the cToken balance for each user
        for (uint256 i = 0; i < unusedDeposits.length; i++) {
            address account = unusedDeposits[i];

            //prettier-ignore
            uint256 amount = unusedDepositBalances[dataVersionNumber][account];
            cTokenBalances[account] = CompoundPoolController.getUnderlyingToCTokens(
                supportedToken,
                amount
            );
            totalCTokenBalance += amount;

            if (!previouslyDeposited[account]) deposited.push(account);

            // Deposit the total unused balance into Compound
            CompoundPoolController.deposit(
                supportedToken,
                totalUnusedBalance,
                comptroller
            );

            // Calculate the total borrow amount
            //prettier-ignore
            uint256 usdBorrowAmount = CompoundPoolController.getMaxUSDBorrowAmount(supportedToken, comptroller);
            //prettier-ignore
            uint256 borrowAmount = CompoundPoolController.calculateMaxBorrowAmount(erc20Contract, usdBorrowAmount, priceFeed).div(2);
            uint256 borrowBalance =
                CompoundPoolController.borrowBalanceCurrent(erc20Contract);

            console.log(borrowAmount);
            console.log(borrowBalance);

            //prettier-ignore
            if (borrowAmount > borrowBalance) borrow(erc20Contract, currencyCode, borrowAmount - borrowBalance);
            else if(borrowBalance > borrowAmount) redeem(erc20Contract, currencyCode, borrowBalance - borrowAmount);

            console.log(CompoundPoolController.borrowBalanceCurrent(erc20Contract));
            console.log(
                CompoundPoolController.getMaxUSDBorrowAmount(supportedToken, comptroller)
            );
        }
    }

    function borrow(
        address erc20Contract,
        string memory currencyCode,
        uint256 amount
    ) private {
        CompoundPoolController.borrow(erc20Contract, amount);
        RariPoolController.deposit(rariStablePool, currencyCode, erc20Contract, amount);
    }

    function redeem(
        address erc20Contract,
        string memory currencyCode,
        uint256 amount
    ) private {
        RariPoolController.withdraw(rariStablePool, currencyCode, amount);
        CompoundPoolController.repayBorrow(erc20Contract, amount);
    }
}
