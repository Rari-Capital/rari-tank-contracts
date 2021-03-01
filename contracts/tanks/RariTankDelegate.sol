pragma solidity 0.7.3;

/* Interfaces */
import {RariTankStorage} from "./RariTankStorage.sol";

import {IRariTank} from "../interfaces/IRariTank.sol";
import {IRariDataProvider} from "../interfaces/IRariDataProvider.sol";

import {IComptroller} from "../external/compound/IComptroller.sol";
import {ICErc20} from "../external/compound/ICErc20.sol";
import {IPriceFeed} from "../external/compound/IPriceFeed.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Libraries */
import {FusePoolController} from "../lib/FusePoolController.sol";
import {RariPoolController} from "../lib/RariPoolController.sol";
import {UniswapController} from "../lib/UniswapController.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {console} from "hardhat/console.sol";

/* External */
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
    @title Rari Tank Delegate
    @author Jet Jadeja <jet@rari.capital>
    @dev Implementation for the USDC Stable Pool tank
*/
contract RariTankDelegate is IRariTank, RariTankStorage, ERC20Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*************
     * Constants *
    *************/
    address private constant BORROWING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string private constant BORROWING_SYMBOL = "USDC";

    /*************
     * Modifiers *
    **************/
    modifier onlyFactory() {
        require(msg.sender != address(0), "RariFundTank: Function can only be called by the rebalancer");
        _;
    }

    /***************
     * Constructor *
    ***************/
    function initialize(
        address _token,
        address _comptroller,
        address _dataProvider
    )
        external
    {
        require(!initialized, "Contract already initialized");
        initialized = true;

        __ERC20_init(
            string(abi.encodePacked("Rari Tank ", ERC20Upgradeable(_token).name())),
            string(abi.encodePacked("rtt-", ERC20Upgradeable(_token).symbol(), "-USDC"))
        );

        token = _token;
        comptroller = _comptroller;
        dataProvider = _dataProvider;

        cToken = address(IComptroller(_comptroller).cTokensByUnderlying(_token));
        require(cToken != address(0), "Unsupported asset");
    }

    /********************
    * External Functions *
    ********************/
    /** @dev Deposit into the Tank */
    function deposit(uint256 amount) external override  {
        uint256 decimals = ERC20Upgradeable(token).decimals();
        uint256 priceMantissa = 32 - decimals;

        uint256 price = IRariDataProvider(dataProvider).getUnderlyingPrice(
            comptroller,
            token
        );
        require(
            price.div(10**priceMantissa).mul(amount).div(10**decimals) >= 500, 
            "RariTankDelegate: Minimum Deposit Amount is $500"
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        uint256 exchangeRate = exchangeRateCurrent();

        dormant += amount; // Increase the tank's total balance
        _mint(msg.sender, amount.mul(exchangeRate).div(10**mantissa)); // Mints RTT
    }

    /** @dev Withdraw from the Tank */
    function withdraw(uint256 amount) external override {
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        uint256 exchangeRate = exchangeRateCurrent();

        uint256 withdrawalAmount = amount.mul(exchangeRate).div(10**mantissa);

        console.log(exchangeRate, "exchange rate");
        console.log(balanceOf(msg.sender), "Sender Balance");
        console.log(withdrawalAmount, "Withdrawal Amount");

        require(withdrawalAmount < balanceOf(msg.sender), "RariTankDelegate: Withdrawal amount must be less than balance");
        console.log("Less than balance");
        _withdraw(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /** @dev Rebalance the pool, depositing dormant funds and handling profits */
    function rebalance() external override onlyFactory {
        console.log("Initial Balance", RariPoolController.balanceOf());
        if(dormant > 0) depositDormantFunds();
        registerProfit();
    }

    /*******************
    * Public Functions *
    ********************/

    /** @return The exchange rate between the RTT and the underlying token */
    function exchangeRateCurrent() 
        public 
        override  
        returns (uint256) 
    {
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        uint256 balance = dormant.add(FusePoolController.balanceOfUnderlying(cToken)).mul(10**mantissa);
        uint256 totalSupply = totalSupply();

        if(balance == 0 || totalSupply == 0) return 50e18; // The initial exchange rate should be 50
        return balance.mul(1e18).div(totalSupply);
    }

    /********************
    * Private Functions *
    *********************/

    /** @dev Deposit dormant funds into a FusePool, borrow a stable asset and put it into the stable pool */
    function depositDormantFunds() private {
        IRariDataProvider rariDataProvider = IRariDataProvider(dataProvider);
        FusePoolController.deposit(comptroller, cToken, dormant);

        uint256 balanceOfUnderlying = FusePoolController.balanceOfUnderlying(cToken);
        uint256 borrowAmountUSD = rariDataProvider.maxBorrowAmountUSD(comptroller, token, balanceOfUnderlying);
        uint256 idealBorrowBalance = rariDataProvider.convertUSDToUnderlying(comptroller, BORROWING, borrowAmountUSD);

        if(idealBorrowBalance > borrowBalance) borrow(idealBorrowBalance - borrowBalance);
        if(borrowBalance > idealBorrowBalance) repay(borrowBalance - idealBorrowBalance);

        dormant = 0;
    }

    /** @dev Register profits and repay interest */
    function registerProfit() private {
        uint256 currentStablePoolBalance = RariPoolController.balanceOf().div(1e12);
        uint256 currentBorrowBalance = FusePoolController.borrowBalanceCurrent(comptroller, BORROWING);

        uint256 profit = currentStablePoolBalance > stablePoolBalance ? 
            currentStablePoolBalance.sub(stablePoolBalance) : 
            0;

        uint256 debt = currentBorrowBalance > borrowBalance ? 
            currentBorrowBalance.sub(borrowBalance) : 
            0;

        if(profit == 0) return;

        RariPoolController.withdraw(BORROWING_SYMBOL, profit);

        if(debt > profit) {
            FusePoolController.repay(comptroller, BORROWING, profit);
            return;
        }

        FusePoolController.repay(comptroller, BORROWING, debt);
        
        uint256 underlyingProfit = swapInterestForUnderlying(profit - debt);
        FusePoolController.deposit(comptroller, cToken, underlyingProfit);
    }

    /** @dev Withdraw funds from protocols */
    function _withdraw(uint256 amount) private {
        // Return if the amount being withdrew is less than or equal the amount of dormant funds
        if (amount <= dormant) return; 
        console.log("Amount wasn't less than dormant");
        // Calculate the amount that must be returned
        uint256 maxBorrow = 
            IRariDataProvider(dataProvider).maxBorrowAmountUSD(comptroller, token, amount);

        console.log("Max borrow", maxBorrow);

        uint256 due = IRariDataProvider(dataProvider)
            .convertUSDToUnderlying(comptroller, BORROWING, maxBorrow)
            .div(2);

        console.log("Due", due);

        // Withdraw and repay
        RariPoolController.withdraw(BORROWING_SYMBOL, due);
        console.log("Withdrew", due);
        FusePoolController.repay(comptroller, BORROWING, due);
        console.log("Repaid", due);

        // Withdraw funds from Fuse
        FusePoolController.withdraw(comptroller, token, amount);
        console.log("Withdrew", amount);
    }

    /** @dev Borrow a stable asset from Fuse and deposit it into Rari */
    function borrow(uint256 amount) private {
        FusePoolController.borrow(comptroller, BORROWING, amount);
        borrowBalance += amount;

        console.log("Rari Balance", RariPoolController.balanceOf());
        RariPoolController.deposit(BORROWING_SYMBOL, BORROWING, amount);
        stablePoolBalance += amount;
        console.log("Rari Balance", RariPoolController.balanceOf());
    }

    /** @dev Withdraw a stable asset from Rari and repay  */
    function repay(uint256 amount) private {
        RariPoolController.withdraw(BORROWING_SYMBOL, amount);
        stablePoolBalance -= amount;

        FusePoolController.repay(comptroller, BORROWING, amount);
        borrowBalance -= amount;
    }

    /** 
        @dev Facilitate a swap from the borrowed token to the underlying token 
        @return The amount of tokens returned by Uniswap
    */
    function swapInterestForUnderlying(uint256 amount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = BORROWING;
        path[1] = token;
        return UniswapController.swapTokens(path, amount);
    }
}