pragma solidity ^0.7.0;

import "./interfaces/IRariDataProvider.sol";
import "./interfaces/IRariFundTank.sol";
import "./interfaces/IRariTankToken.sol";

import {CompoundPoolController} from "./lib/CompoundPoolController.sol";
import {RariPoolController} from "./lib/RariPoolController.sol";
import {UniswapController} from "./lib/UniswapController.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RariFundTank is IRariFundTank, Ownable {
    using SafeMath for uint256;
    //using RariPoolController for address;
    //using CompoundPoolController for address;

    ///@dev The address of the ERC20 token supported by the tank
    address private supportedToken;

    ///@dev The decimal precision of the ERC20 token supported by the tank
    uint256 private decimals;

    ///@dev The address of the ERC20Token to be borrowed
    address private borrowToken;

    ///@dev The address of the corresponding Rari Tank Token
    address private rariTankToken;

    ///@dev The RariDataProvider Contract
    IRariDataProvider private rariDataProvider;

    ///@dev The total cToken balance
    uint256 private totalCTokenBalance;

    ///@dev An array of addresses who have deposited and have a balance of more than 0 cToken
    address[] private deposited;

    ///@dev Maps an address to a boolean indicated whether or not they have previously deposited
    mapping(address => bool) private previouslyDeposited;

    ///@dev Maps user addresses to their cToken balances
    mapping(address => uint256) private cTokenBalances;

    ///@dev Token exchange rate
    uint256 private tokenExchangeRate;

    constructor(
        address _supportedToken,
        uint256 _decimals,
        address _borrowToken,
        address _rariDataProvider,
        address _rariTankToken
    ) Ownable() {
        supportedToken = _supportedToken;
        decimals = _decimals;
        borrowToken = _borrowToken;
        rariDataProvider = IRariDataProvider(_rariDataProvider);
        rariTankToken = _rariTankToken;

        IRariTankToken(_rariTankToken).initialize();
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
    function deposit(address account, uint256 amount) external override onlyOwner() {
        require(
            rariDataProvider.getPrice(supportedToken, amount).div(1e18) >= 500,
            "RariFundTank: Deposit amount must be over 500 dollars"
        );

        uint256 mantissa = 18 - decimals;
        uint256 exchangeRate = getTokenExchangeRate();
        uint256 mintAmount = amount.mul(10**mantissa).mul(exchangeRate).div(1e18);
        IRariTankToken(rariTankToken).mint(account, mintAmount);

        totalUnusedBalance += amount;
    }

    function withdraw(address account, uint256 amount)
        external
        override
        onlyOwner()
        returns (address, uint256)
    {
        uint256 mantissa = 36 - decimals;
        uint256 exchangeRate = getTokenExchangeRate();

        uint256 tankTokenAmount = amount.mul(10**mantissa).div(exchangeRate);
        uint256 tankTokenBalance = IRariTankToken(rariTankToken).balanceOf(account);

        require(
            tankTokenBalance >= tankTokenAmount,
            "RariFundTank: Amount exceeds balance!"
        );
        _withdraw(amount);
        IERC20(supportedToken).transfer(account, amount);

        return (rariTankToken, tankTokenAmount);
    }

    /**
        @dev Deposits unused funds into Compound and borrows another asset
    */
    function rebalance() external override onlyOwner() {
        uint256 profit;
        uint256 currentPoolBalance = RariPoolController.getUSDBalance();

        if (currentPoolBalance > stablePoolBalance)
            profit = currentPoolBalance.sub(stablePoolBalance).div(1e12);

        if (profit > 1e6) split(profit);
        if (totalUnusedBalance > 0) depositUnusedFunds("USDC");

        delete unusedDeposits;
        delete totalUnusedBalance;
        dataVersionNumber++;
    }

    /**
        @dev Return the exchange rate of the corresponding tank token
    */
    function getTokenExchangeRate() public override returns (uint256) {
        uint256 mantissa = 18 - decimals;
        uint256 balance =
            CompoundPoolController
                .balanceOfUnderlying(supportedToken)
                .add(totalUnusedBalance)
                .mul(10**mantissa);
        uint256 totalSupply = IERC20(rariTankToken).totalSupply();

        if (balance == 0 || totalSupply == 0) return 1e18;
        return balance.mul(1e18).div(totalSupply);
    }

    /**
        @dev Given a certain USD gain from the pool, split it among all of the depositors
        @param amount The amount to split
    */
    function split(uint256 amount) private {
        RariPoolController.withdraw("USDC", amount);
        uint256 amountOut = swapInterestForUnderlying(amount);
        if (amountOut == 0) {
            return;
        }

        CompoundPoolController.deposit(supportedToken, amountOut);
        stablePoolBalance = RariPoolController.getUSDBalance();
    }

    /**
        @dev Deposit unused funds into the tanks
    */
    function depositUnusedFunds(string memory currencyCode) private {
        // Deposit the total unused balance into Compound
        CompoundPoolController.deposit(supportedToken, totalUnusedBalance);

        // Calculate the total borrow amount
        //prettier-ignore
        uint256 usdBorrowAmount = rariDataProvider.getMaxUSDBorrowAmount(supportedToken, totalUnusedBalance);
        //prettier-ignore
        uint256 borrowAmount = rariDataProvider.getUSDToUnderlying(borrowToken, usdBorrowAmount).div(2);
        uint256 borrowBalance = rariDataProvider.borrowBalanceCurrent(borrowToken);

        //prettier-ignore
        if (borrowAmount > borrowBalance) borrow(borrowToken, currencyCode, borrowAmount - borrowBalance);
        else if(borrowBalance > borrowAmount) redeem(borrowToken, currencyCode, borrowBalance - borrowAmount);
    }

    /**
        @dev Withdraw funds from the used protocols

    */
    function _withdraw(uint256 amount) private {
        if (amount <= totalUnusedBalance) return;

        // Calculate the USD amount to be returned
        uint256 usdRepayAmount =
            rariDataProvider.getMaxUSDBorrowAmount(supportedToken, amount);
        uint256 repayAmount =
            rariDataProvider.getUSDToUnderlying(borrowToken, usdRepayAmount).div(2);

        // Allocate funds that have been deposited into Compound
        RariPoolController.withdraw("USDC", repayAmount);
        uint256 balance = IERC20(borrowToken).balanceOf(address(this));
        if (repayAmount > balance) repayAmount = balance;

        CompoundPoolController.repayBorrow(borrowToken, repayAmount);
        CompoundPoolController.withdraw(supportedToken, amount);
    }

    function borrow(
        address erc20Contract,
        string memory currencyCode,
        uint256 amount
    ) private {
        CompoundPoolController.borrow(erc20Contract, amount);
        RariPoolController.deposit(currencyCode, erc20Contract, amount);
        stablePoolBalance += amount.mul(1e12);
    }

    function redeem(
        address erc20Contract,
        string memory currencyCode,
        uint256 amount
    ) private {
        RariPoolController.withdraw(currencyCode, amount);
        CompoundPoolController.repayBorrow(erc20Contract, amount);
        stablePoolBalance -= amount.mul(1e12);
    }

    function swapInterestForUnderlying(uint256 amount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = borrowToken;
        path[1] = supportedToken;
        return UniswapController.swapTokens(path, amount);
    }
}
