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
import {FusePoolController} from "../lib/FusePoolController.sol";
import {RariPoolController} from "../lib/RariPoolController.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

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
        require(msg.sender == factory, "RariFundTank: Function can only be called by the factory");
        _;
    }

    /***************
     * Constructor *
    ***************/
    function initialize(
        address _token,
        address _comptroller,
        address _factory
    )
        external
    {
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
    function deposit(uint256 amount) external override  {
        uint256 decimals = ERC20Upgradeable(token).decimals();
        uint256 priceMantissa = 36 - decimals;

        uint256 price = FusePoolController.getUnderlyingInEth(
            comptroller,
            token
        );

        uint256 deposited = price
            .div(10 ** (priceMantissa - 18))
            .mul(amount)
            .div(10**decimals);
        
        require(
            deposited >= 1e18, 
            "RariTankDelegate: Minimum Deposit Amount is $500"
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if(paid <= 3e17) {
            uint256 left = 3e17 - paid;

            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = ROUTER.WETH();

            if(deposited.div(40) > left) {
                IERC20(token).approve(address(ROUTER), amount.div(40));

                uint256[] memory amounts = ROUTER.swapTokensForExactETH(
                    left,
                    amount.div(40),
                    path, 
                    address(this), 
                    block.timestamp
                );

                amount -= amounts[0];
                KPR.addCreditETH{value: amounts[1]}(factory);
            }

            else {
                IERC20(token).approve(address(ROUTER), amount.div(40));

                uint256[] memory amounts = ROUTER.swapTokensForExactETH(
                    deposited.div(40),
                    amount.div(40),
                    path, 
                    address(this), 
                    block.timestamp
                );

                amount -= amounts[0];
                KPR.addCreditETH{value: amounts[1]}(factory);
            }
        }

        uint256 exchangeRate = exchangeRateCurrent();

        _mint(msg.sender, amount.mul(exchangeRate).div(10**decimals)); // Mints RTT
    }

    /** @dev Withdraw from the Tank */
    function withdraw(uint256 amount) external override {
        uint256 balance = underlyingBalanceOf(msg.sender);

        require(
            balance > amount,
            "RariTankDelegate: Withdrawal amount must be less than balance"
        );

        _withdraw(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /** @dev Rebalance the pool, depositing dormant funds and handling profits */
    function rebalance() external override onlyFactory {
        require(canRebalance(), "Rebalance unecessary");
        if(dormant() > 0) depositDormantFunds();
        registerProfit();
        delete paid;
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
        uint256 balance = dormant()
            .add(FusePoolController.balanceOfUnderlying(cToken))
            .mul(10**mantissa);
        uint256 totalSupply = totalSupply();

        if(balance == 0 || totalSupply == 0) return 1e18; // The initial exchange rate should be 1
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
        uint256 mantissa = 36 - ERC20Upgradeable(token).decimals();
        uint256 exchangeRate = exchangeRateCurrent();

        return totalSupply().mul(exchangeRate).div(10**mantissa);
    }

    /** @return A bool that indicates whether the tank can be rebalanced */
    function canRebalance() public returns (bool) {
        uint256 totalBalance = totalUnderlyingBalance();
        bool dormantGreater = dormant() >= totalBalance.div(20);

        uint256 borrowAmountUSD = FusePoolController.maxBorrowAmountUSD(
            comptroller, 
            token, 
            FusePoolController.balanceOfUnderlying(cToken)
        );

        uint256 borrowAmountUnderlying = FusePoolController.convertUSDToUnderlying(comptroller, BORROWING, borrowAmountUSD);
        uint256 borrowBalanceCurrent = FusePoolController.borrowBalanceCurrent(comptroller, BORROWING);

        uint256 divergence = 
            borrowBalanceCurrent > borrowBalance ? borrowBalanceCurrent - borrowBalance :  
            borrowBalance > borrowBalanceCurrent ? borrowBalance - borrowBalanceCurrent : 
            0;

        bool gainedGreater;
        uint256 currentPoolBalance = RariPoolController.balanceOf();
        if (currentPoolBalance > yieldPoolBalance) {
            uint256 threshold = yieldPoolBalance.div(20);
            gainedGreater = 
                (currentPoolBalance - yieldPoolBalance) >= threshold;
        }

        return (
            dormantGreater ||
            divergence >= borrowAmountUnderlying.div(5) ||
            gainedGreater
        );
    }

    /********************
    * Internal Functions *
    *********************/

    /** @dev Deposit dormant funds into a FusePool, borrow a stable asset and put it into the stable pool */
    function depositDormantFunds() internal {
        FusePoolController.deposit(comptroller, cToken, dormant());

        uint256 balanceOfUnderlying = FusePoolController.balanceOfUnderlying(cToken);
        uint256 borrowAmountUSD = FusePoolController.maxBorrowAmountUSD(comptroller, token, balanceOfUnderlying);
        uint256 idealBorrowBalance = FusePoolController.convertUSDToUnderlying(comptroller, BORROWING, borrowAmountUSD).div(2);

        if(idealBorrowBalance > borrowBalance) borrow(idealBorrowBalance - borrowBalance);
        if(borrowBalance > idealBorrowBalance) repay(borrowBalance - idealBorrowBalance);
    }

    /** @dev Register profits and repay interest */
    function registerProfit() internal {
        uint256 currentStablePoolBalance = RariPoolController.balanceOf();
        uint256 currentBorrowBalance = FusePoolController.borrowBalanceCurrent(comptroller, BORROWING);

        uint256 profit = currentStablePoolBalance > yieldPoolBalance ? 
            currentStablePoolBalance.sub(yieldPoolBalance) : 
            0;


        uint256 debt = currentBorrowBalance > borrowBalance ? 
            currentBorrowBalance.sub(borrowBalance) : 
            0;



        if(profit == 0) return;

        RariPoolController.withdraw(BORROWING_SYMBOL, profit);
        yieldPoolBalance = RariPoolController.balanceOf();

        if(debt >= profit) {
            FusePoolController.repay(comptroller, BORROWING, profit);
            return;
        }


        FusePoolController.repay(comptroller, BORROWING, debt);
        
        uint256 underlyingProfit = swapInterestForUnderlying(profit - debt);
        FusePoolController.deposit(comptroller, cToken, underlyingProfit);
    }

    /** @dev Withdraw funds from protocols */
    function _withdraw(uint256 amount) internal {
        // Return if the amount being withdrew is less than or equal the amount of dormant funds
        if (amount <= dormant()) {
            return;
        }

        else if (dormant() > 0) amount -= dormant();
        
        // Calculate the amount that must be returned
        uint256 totalSupplied = FusePoolController.balanceOfUnderlying(cToken);
        uint256 represents = amount.mul(1e18).div(totalSupplied);

        uint256 totalBorrowed = FusePoolController.borrowBalanceCurrent(comptroller, BORROWING);
        uint256 due = totalBorrowed.mul(represents).div(1e18);

        repay(due);

        // Withdraw funds from Fuse
        FusePoolController.withdraw(comptroller, token, amount);
    }

    /** @dev Borrow a stable asset from Fuse and deposit it into Rari */
    function borrow(uint256 amount) internal {
        FusePoolController.borrow(comptroller, BORROWING, amount);
        borrowBalance += amount;

        RariPoolController.deposit(BORROWING_SYMBOL, BORROWING, amount);
        yieldPoolBalance += amount;
    }

    /** @dev Withdraw a stable asset from Rari and repay */
    function repay(uint256 amount) internal {
        RariPoolController.withdraw(BORROWING_SYMBOL, amount);
        yieldPoolBalance -= amount;

        FusePoolController.repay(comptroller, BORROWING, amount);
        borrowBalance -= amount;
    }

    /**
        @return a count of the tank's undeposited funds
    */
    function dormant() internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /** 
        @dev Facilitate a swap from the borrowed token to the underlying token 
        @return The amount of tokens returned by Uniswap
    */
    function swapInterestForUnderlying(uint256 amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = BORROWING;
        path[1] = token;

        IERC20(BORROWING).approve(address(ROUTER), amount);
        return ROUTER.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp)[1];
    }

    receive() external payable {}
}