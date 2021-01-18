pragma solidity ^0.7.0;

import "./lib/CompoundPoolController.sol";
import "./lib/RariPoolController.sol";
import "./lib/SushiswapController.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract RariFundTank is Ownable {
    using SafeMath for uint256;
    //using RariPoolController for address;
    //using CompoundPoolController for address;

    ///@dev The address of the ERC20Token supported by the tank
    address private supportedToken;

    ///@dev The address of the ERC20Token to be borrowed
    address private borrowToken;

    ///@dev Compound's Comptroller Contract
    address private comptroller;

    ///@dev Compound's Pricefeed program
    address private priceFeed;

    ///@dev The address of the Rari Stable Pool Fund Manager
    address private rariStablePool;

    ///@dev The address of the SushiswapRouter
    address private sushiswapRouter;

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
        address _borrowToken,
        address _comptroller,
        address _priceFeed,
        address _rariStablePool
    ) Ownable() {
        supportedToken = _supportedToken;
        borrowToken = _borrowToken;
        comptroller = _comptroller;
        priceFeed = _priceFeed;
        rariStablePool = _rariStablePool;

        sushiswapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
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
            CompoundPoolController.getPrice(supportedToken, amount, priceFeed).div(
                1e18
            ) >= 500,
            "RariFundTank: Deposit amount must be over 500 dollars"
        );
        //prettier-ignore
        if (unusedDepositBalances[dataVersionNumber][account] == 0) unusedDeposits.push(account);
        unusedDepositBalances[dataVersionNumber][account] += amount;
        totalUnusedBalance += amount;
    }

    function withdraw(address account, uint256 amount) external onlyOwner() {
        uint256 cTokenBalance = cTokenBalances[account];
        uint256 depositedFunds =
            CompoundPoolController.getCTokensToUnderlying(supportedToken, cTokenBalance);
        uint256 dormantFunds = unusedDepositBalances[dataVersionNumber][account];

        // Withdraw funds from protocols
        withdrawFunds(account, amount, dormantFunds, usdProfit[account], depositedFunds);
        IERC20(supportedToken).approve(account, amount);
    }

    /**
        @dev Deposits unused funds into Compound and borrows another asset
    */
    function rebalance() external onlyOwner() {
        uint256 profit;
        uint256 currentPoolBalance = RariPoolController.getUSDBalance(rariStablePool);

        if (currentPoolBalance > stablePoolBalance)
            profit = currentPoolBalance.sub(stablePoolBalance);

        if (profit > 0) split(profit);
        if (totalUnusedBalance > 0) depositUnusedFunds("USDC");

        delete unusedDeposits;
        delete totalUnusedBalance;
        dataVersionNumber++;
    }

    /**
        @dev Return the given user's interest earned in USD
        @param account The address of the user
    */
    function getInterestEarned(address account) external view returns (uint256) {
        return usdProfit[account];
    }

    /**
        @dev Given a certain USD gain from the pool, split it among all of the depositors
        @param amount The amount to split
    */
    function split(uint256 amount) private {
        console.log(amount, "profit");
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
    */
    function depositUnusedFunds(string memory currencyCode) private {
        // Calculate the cToken balance for each user
        for (uint256 i = 0; i < unusedDeposits.length; i++) {
            address account = unusedDeposits[i];
            //prettier-ignore
            uint256 amount = unusedDepositBalances[dataVersionNumber][account];
            uint256 cTokenAmount =
                CompoundPoolController.getUnderlyingToCTokens(supportedToken, amount);
            cTokenBalances[account] = cTokenAmount;
            totalCTokenBalance += cTokenAmount;

            if (!previouslyDeposited[account]) deposited.push(account);
        }
        // Deposit the total unused balance into Compound
        CompoundPoolController.deposit(supportedToken, totalUnusedBalance, comptroller);
        // Calculate the total borrow amount
        //prettier-ignore
        uint256 usdBorrowAmount = CompoundPoolController.getMaxUSDBorrowAmount(supportedToken, totalUnusedBalance, comptroller, priceFeed);
        //prettier-ignore
        uint256 borrowAmount = CompoundPoolController.getUSDToUnderlying(borrowToken, usdBorrowAmount, priceFeed).div(2);
        uint256 borrowBalance = CompoundPoolController.borrowBalanceCurrent(borrowToken);

        //prettier-ignore
        if (borrowAmount > borrowBalance) borrow(borrowToken, currencyCode, borrowAmount - borrowBalance);
        else if(borrowBalance > borrowAmount) redeem(borrowToken, currencyCode, borrowBalance - borrowAmount);
    }

    /**
        @dev Withdraw funds from the used protocols
        @param account The address that is withdrawing their funds
        @param amount The amount of tokens to be withdrew
        @param dormantFunds Funds that have not been moved
        @param interestEarned Funds that have been earned through the Rari Stable Pool
        @param depositedFunds Funds that have been deposited into Compound

    */
    function withdrawFunds(
        address account,
        uint256 amount,
        uint256 dormantFunds,
        uint256 interestEarned,
        uint256 depositedFunds
    ) private {
        uint256 interestInUnderlying =
            CompoundPoolController.getUSDToUnderlying(
                supportedToken,
                interestEarned,
                priceFeed
            );

        uint256 underlyingBalance =
            depositedFunds.add(dormantFunds).add(interestInUnderlying);

        require(
            amount <= underlyingBalance,
            "RariFundTank: Withdrawal amount higher than current balance"
        );
        uint256 leftAmount = amount;

        // Allocate dormant funds towards withdrawals
        if (dormantFunds != 0 && leftAmount > dormantFunds) {
            leftAmount -= dormantFunds;
            // Clear unused fund data
            totalUnusedBalance -= dormantFunds;
            unusedDepositBalances[dataVersionNumber][account] == 0;
        } else if (dormantFunds != 0 && leftAmount <= dormantFunds) {
            //Clear unused fund data
            totalUnusedBalance -= amount;
            unusedDepositBalances[dataVersionNumber][account] -= amount;

            return;
        }

        // Allocate borrowed funds towards withdrawal
        if (interestEarned != 0 && leftAmount > interestInUnderlying) {
            RariPoolController.withdraw(rariStablePool, "USDC", interestEarned);
            usdProfit[account] = 0;
            swapInterestForUnderlying(interestEarned);
        } else if (interestEarned != 0 && leftAmount <= interestInUnderlying) {
            RariPoolController.withdraw(rariStablePool, "USDC", interestEarned);
            usdProfit[account] -= interestEarned;

            swapInterestForUnderlying(interestEarned);

            return;
        }

        // Calculate the USD amount to be returned
        uint256 usdRepayAmount =
            CompoundPoolController.getMaxUSDBorrowAmount(
                supportedToken,
                leftAmount,
                comptroller,
                priceFeed
            );

        uint256 repayAmount =
            CompoundPoolController
                .getUSDToUnderlying(borrowToken, usdRepayAmount, priceFeed)
                .div(2);

        // Allocate funds that have been deposited into Compound
        RariPoolController.withdraw(rariStablePool, "USDC", repayAmount);
        uint256 balance = IERC20(borrowToken).balanceOf(address(this));
        if (repayAmount > balance) repayAmount = balance;

        CompoundPoolController.repayBorrow(borrowToken, repayAmount);
        CompoundPoolController.withdraw(supportedToken, leftAmount);
    }

    function borrow(
        address erc20Contract,
        string memory currencyCode,
        uint256 amount
    ) private {
        CompoundPoolController.borrow(erc20Contract, amount);
        RariPoolController.deposit(rariStablePool, currencyCode, erc20Contract, amount);
        stablePoolBalance += amount;
    }

    function redeem(
        address erc20Contract,
        string memory currencyCode,
        uint256 amount
    ) private {
        RariPoolController.withdraw(rariStablePool, currencyCode, amount);
        CompoundPoolController.repayBorrow(erc20Contract, amount);
        stablePoolBalance -= amount;
    }

    function swapInterestForUnderlying(uint256 amount) private {
        // function swapExactTokensForTokens(
        //     uint amountIn,
        //     uint amountOutMin,
        //     address[] calldata path,
        //     address to,
        //     uint deadline
        // ) external returns (uint[] memory amounts);

        address[] memory path = new address[](2);
        path[0] = borrowToken;
        path[1] = supportedToken;

        //SushiswapController.swapTokens(path, amount);

        // IUniswapV2Router02(sushiswapRouter).swapExactTokensForTokens(
        //     amount,
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp
        // );
    }
}
