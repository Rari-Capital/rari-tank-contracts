pragma solidity 0.7.3;

/* Interfaces */
import {RariTankStorage} from "./RariTankStorage.sol";
import {IRariTank} from "../interfaces/IRariTank.sol";

import {IComptroller} from "../external/compound/IComptroller.sol";
import {ICErc20} from "../external/compound/ICErc20.sol";
import {IPriceFeed} from "../external/compound/IPriceFeed.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../external/uniswapv2/IUniswapV2Router.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {FusePoolController} from "../lib/FusePoolController.sol";
import {RariPoolController} from "../lib/RariPoolController.sol";
import {UniswapV2Library} from "../external/uniswapv2/UniswapV2Library.sol";

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
     * Modifiers *
     **************/
    modifier onlyFactory() {
        require(
            msg.sender == factory,
            "RariFundTank: Function can only be called by the factory"
        );
        _;
    }

    /***************
     * Constructor *
     ***************/
    function initialize(
        address _token,
        address _comptroller,
        address _factory
    ) external {
        require(!initialized, "Contract already initialized");
        initialized = true;

        __ERC20_init(
            string(abi.encodePacked("Tank ", ERC20Upgradeable(_token).name())),
            string(abi.encodePacked("rtt-", ERC20Upgradeable(_token).symbol(), "-DAI"))
        );

        token = _token;
        comptroller = _comptroller;
        factory = _factory;

        cToken = address(IComptroller(_comptroller).cTokensByUnderlying(_token));
        require(cToken != address(0), "Unsupported asset");
    }

    /********************
     * External Functions *
     ********************/

    /** @dev Deposit into the Tank */
    function deposit(uint256 amount) external override {
        uint256 decimals = ERC20Upgradeable(token).decimals();
        uint256 priceMantissa = 18 - decimals;

        uint256 price = FusePoolController.getUnderlyingInEth(comptroller, token);
        uint256 deposited = price.div(10**priceMantissa).mul(amount).div(10**decimals);

        require(deposited >= 1e18, "RariTankDelegate: Minimum Deposit Amount is $500");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 exchangeRate = exchangeRateCurrent();
        FusePoolController.deposit(comptroller, cToken, amount);
        _mint(msg.sender, amount.mul(exchangeRate).div(10**decimals)); // Mints RTT
    }

    /** @dev Withdraw from the Tank */
    function withdraw(uint256 amount) external override {
        uint256 balance = underlyingBalanceOf(msg.sender);

        require(
            balance >= amount,
            "RariTankDelegate: Withdrawal amount must be less than balance"
        );

        _withdraw(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /** @dev Pay Keep3r Bot */
    function supplyKeeperPayment(uint256 amount) external override onlyFactory {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = ROUTER.WETH();
        uint256 swapAmount = UniswapV2Library.getAmountsIn(ROUTER.factory(), amount, path)[0];
        
        FusePoolController.withdraw(comptroller, token, swapAmount);
        IERC20(token).approve(address(ROUTER), swapAmount);
        ROUTER.swapTokensForExactETH(amount, swapAmount, path, factory, block.timestamp);
    }

    /** @dev Rebalance the pool, depositing dormant funds and handling profits */
    function rebalance(bool useWeth) external override onlyFactory {
        (uint256 profit, bool profitSufficient) = _getProfits(5e15); //0.5%
        (uint256 divergence, bool idealGreater, bool divergenceSufficient) =
            _getBorrowBalanceDivergence(75e17);

        require(
            profitSufficient || divergenceSufficient,
            "RariTank: Tank cannot be rebalanced"
        );

        bool shouldRegisterProfit = profit > yieldPoolBalance.div(400) && profit != 0;

        if (divergenceSufficient) {
            if (idealGreater) {
                _borrow(divergence, shouldRegisterProfit ? profit : 0);
            } else {
                _repay(divergence, shouldRegisterProfit ? profit : 0);
            }
        }

        if (shouldRegisterProfit) _registerProfit(profit, useWeth);
    }

    /*******************
     * Public Functions *
    ********************/

    /** @return The exchange rate between the RTT and the underlying token */
    function exchangeRateCurrent() public override returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        uint256 balance =
            FusePoolController.balanceOfUnderlying(cToken).mul(10**mantissa);

        if (balance == 0 || totalSupply == 0) return 1e18; // The initial exchange rate should be 1
        return balance.mul(1e18).div(totalSupply);
    }

    /** @dev Get an address's underlying balance */
    function underlyingBalanceOf(address account) public returns (uint256) {
        uint256 tankTokenBalance = balanceOf(account);
        uint256 mantissa = 36 - ERC20Upgradeable(token).decimals();
        uint256 exchangeRate = exchangeRateCurrent();

        return tankTokenBalance.mul(exchangeRate).div(10**mantissa);
    }

    /** @dev Get the tank's total underlying balance */
    function totalUnderlyingBalance() public returns (uint256) {
        return FusePoolController.balanceOfUnderlying(token);
    }

    /********************
     * Internal Functions *
     *********************/

    /** @dev Register profits and repay interest */
    function _registerProfit(uint256 profit, bool useWeth) internal {
        uint256 currentBorrowBalance =
            FusePoolController.borrowBalanceCurrent(comptroller, BORROWING);

        uint256 debt =
            currentBorrowBalance > borrowBalance
                ? currentBorrowBalance.sub(borrowBalance)
                : 0;

        RariPoolController.withdraw(BORROWING_SYMBOL, profit);
        yieldPoolBalance = RariPoolController.balanceOf();

        if (debt >= profit) {
            FusePoolController.repay(comptroller, BORROWING, profit);
            return;
        }

        FusePoolController.repay(comptroller, BORROWING, debt);

        uint256 underlyingProfit = _swapInterestForUnderlying(profit - debt, useWeth);
        FusePoolController.deposit(comptroller, cToken, underlyingProfit);
    }

    /** @dev _getBorrowBalanceDivergence */
    function _getBorrowBalanceDivergence(uint256 percentThreshold)
        internal
        returns (
            uint256 divergence,
            bool idealGreater,
            bool divergenceSufficient
        )
    {
        uint256 idealBorrowBalance = _idealBorrowAmount();

        divergence = idealBorrowBalance < borrowBalance
            ? borrowBalance - idealBorrowBalance
            : idealBorrowBalance > borrowBalance
            ? idealBorrowBalance - borrowBalance
            : 0;

        idealGreater = idealBorrowBalance > borrowBalance;

        uint256 borrowThreshold = borrowBalance.mul(percentThreshold).div(1e18);
        divergenceSufficient = divergence > borrowThreshold;
    }

    /** 
        @dev Calculate profit and evaluate whether profit is above a certain threshold
        @param percentThreshold The percentage threshold for profits 
    */
    function _getProfits(uint256 percentThreshold)
        internal
        returns (uint256 profit, bool profitSufficient)
    {
        profit = RariPoolController.balanceOf().sub(yieldPoolBalance);

        uint256 threshold = yieldPoolBalance.mul(percentThreshold).div(1e18);
        profitSufficient = profit > threshold;
    }

    /** @dev Calculate the ideal borrow balance */
    function _idealBorrowAmount() internal returns (uint256) {
        uint256 balanceOfUnderlying = FusePoolController.balanceOfUnderlying(cToken);
        uint256 borrowAmountUSD =
            FusePoolController.maxBorrowAmountUSD(
                comptroller,
                token,
                balanceOfUnderlying
            );

        return
            FusePoolController
                .convertUSDToUnderlying(comptroller, BORROWING, borrowAmountUSD)
                .div(2);
    }

    /** @dev Withdraw funds from protocols */
    function _withdraw(uint256 amount) internal {
        // Calculate the amount that must be returned
        uint256 totalSupplied = FusePoolController.balanceOfUnderlying(cToken);
        uint256 represents = amount.mul(1e18).div(totalSupplied);

        uint256 totalBorrowed =
            FusePoolController.borrowBalanceCurrent(comptroller, BORROWING);
        uint256 due = totalBorrowed.mul(represents).div(1e18);

        _repay(due, 0);

        // Withdraw funds from Fuse
        FusePoolController.withdraw(comptroller, token, amount);
    }

    /** @dev Borrow a stable asset from Fuse and deposit it into Rari */
    function _borrow(uint256 borrowAmount, uint256 depositAmount) internal {
        FusePoolController.borrow(comptroller, BORROWING, borrowAmount);
        borrowBalance += borrowAmount;

        depositAmount = depositAmount != 0 ? borrowAmount - depositAmount : borrowAmount;

        RariPoolController.deposit(BORROWING_SYMBOL, BORROWING, depositAmount);
        yieldPoolBalance += depositAmount;
    }

    /** @dev Withdraw a stable asset from Rari and repay */
    function _repay(uint256 withdrawalAmount, uint256 repayAmount) internal {
        RariPoolController.withdraw(BORROWING_SYMBOL, withdrawalAmount);
        yieldPoolBalance -= withdrawalAmount;

        repayAmount = repayAmount != 0
            ? withdrawalAmount - repayAmount
            : withdrawalAmount;

        FusePoolController.repay(comptroller, BORROWING, repayAmount);
        borrowBalance -= repayAmount;
    }

    /** 
        @dev Facilitate a swap from the borrowed token to the underlying token 
        @return The amount of tokens returned by Uniswap
    */
    function _swapInterestForUnderlying(uint256 amount, bool useWeth) internal returns (uint256) {
        uint256 size;
        if(useWeth) size = 3;
        else size = 2;

        address[] memory path = new address[](size);
        path[0] = BORROWING;

        if(useWeth) {
            path[1] = ROUTER.WETH();
            path[2] = token;
        } else {
            path[1] = token;
        }

        IERC20(BORROWING).approve(address(ROUTER), amount);
        
        return ROUTER.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        )[size - 1];
    }

    receive() external payable {}
}
