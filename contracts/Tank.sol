pragma solidity 0.7.3;

/* Storage */
import {TankStorage} from "./helpers/tanks/TankStorage.sol";
import {ITank} from "./interfaces/ITank.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";

/* Interfaces */
import {IComptroller} from "./external/compound/IComptroller.sol";
import {ICErc20} from "./external/compound/ICErc20.sol";
import {IPriceFeed} from "./external/compound/IPriceFeed.sol";
import {IFusePoolDirectory} from "./external/fuse/IFusePoolDirectory.sol";

//prettier-ignore
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IUniswapV2Router02} from "./external/uniswapv2/IUniswapV2Router.sol";
import {AggregatorV3Interface} from "./external/chainlink/AggregatorV3Interface.sol";

/* Libraries */
import {MarketController} from "./libraries/MarketController.sol";
import {YieldSourceController} from "./libraries/YieldSourceController.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

/** 
    @title Tank
    @author Jet Jadeja <jet@rari.capital>
    @dev The default Tank contract, supplies an asset to Fuse, borrows another asset, and earns interest on it.
*/
contract Tank is TankStorage, ERC20Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*************
     * Variables *
     *************/

    /** @dev The address of the ERC20 token that users deposit and earn yield on in the Tank */
    address public token;

    /** @dev The address of the Fuse fToken that represents the Tank's collateral */
    address public cToken;

    /** @dev The token that the Tank borrows and deposits into a yield source */
    address public borrowing;

    /** @dev Address of the FusePool Comptroller contract */
    address public comptroller;

    /** @dev A value representing the ideal collateral utilization, scaled by 1e18 */
    uint256 public idealCollateralUtilization;

    /** @dev Borrow balance, set whenever funds are borrowed or repaid */
    uint256 internal lastBorrowBalance;

    /** @dev Yield source Balance, set whenever funds are deposited or withdrew */
    uint256 internal lastYieldSourceBalance;

    /** @dev The address for the WETH contract */
    address internal WETH;

    /** @dev Uniswap router address */
    address internal router;

    /** @dev Maps addresses to the block number of their last action */
    mapping(address => uint256) internal lastAction;

    /** @dev Chainlink oracle for gas prices */
    AggregatorV3Interface constant FASTGAS =
        AggregatorV3Interface(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);

    /***************
     * Constructor *
     ***************/
    /** 
        @dev Initialize the Tank contract 
        @param data A bytes parameter representing the constructor arguments
    */
    function initialize(bytes memory data) external initializer {
        // Extract the token and comptroller addresses from the bytes parameter
        (address _token, address _comptroller) = abi.decode(data, (address, address));

        require(
            IFusePoolDirectory(0x835482FE0532f169024d5E9410199369aAD5C77E).poolExists(
                _comptroller
            ),
            "TankFactory: Invalid Comptroller address"
        );

        token = _token;
        comptroller = _comptroller;

        /* 
            Ideally, these would be a constant state variables, 
            but since this is a proxy contract it would be unsafe to do so
        */
        borrowing = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        idealCollateralUtilization = 55e16; // 55%

        string memory borrowSymbol = ERC20Upgradeable(borrowing).symbol();
        cToken = address(IComptroller(_comptroller).cTokensByUnderlying(_token));
        MarketController.enterMarkets(cToken, _comptroller);

        __ERC20_init(
            string(abi.encodePacked("Tank ", ERC20Upgradeable(_token).name())),
            string(
                abi.encodePacked("rtt-", ERC20Upgradeable(_token).symbol(), borrowSymbol)
            )
        );

        require(cToken != address(0), "Unsupported asset");
        require(
            address(IComptroller(_comptroller).cTokensByUnderlying(borrowing)) !=
                address(0),
            "Unsupported borrow asset"
        );
    }

    /*************
     * Mofifiers *
     *************/

    /** 
        @dev Pay the caller of a function in underlying tokens 
        This modifier is used for rebalances
    */
    modifier pay() {
        uint256 gas = gasleft();
        _;
        uint256 used = 13e5 + gas - gasleft(); // Gas used to call the method added to the gas used by this modifier (13e5)
        uint256 decimals = ERC20Upgradeable(token).decimals();

        uint256 price =
            MarketController.getPriceEth(comptroller, token).mul(10**decimals).div(1e18);
        (, int256 gasPrice, , , ) = FASTGAS.latestRoundData();

        uint256 fee = used.mul(uint256(gasPrice)); // The fee, paid by the caller in ETH
        uint256 toPay = fee.mul(10**decimals).div(price); // Calculate the fee, paid by the caller, in tokens

        withdrawFunds(toPay); // Withdraw funds from Fuse
        IERC20(token).safeTransfer(msg.sender, toPay); // Transfer compensation to caller
    }

    /** 
        @dev Ensure that users don't call a method until a certain number of blocks have passed 
        @param blocks The number of blocks that the call must occur after the last action
        The minimum number of blocks that must be mined after the last action for this method to be callable
    */
    modifier blockLock(uint256 blocks) {
        require(
            (lastAction[msg.sender] + blocks) <= block.number,
            "Tank: Must call in a later block"
        );
        _;

        lastAction[msg.sender] = block.number; // Set new last action
    }

    /********************
     * External Functions *
     *********************/
    /** @dev Deposit into the Tank */
    function deposit(uint256 amount) external blockLock(300) {
        //300 blocks is about one hour
        require(msg.sender == tx.origin, "Tank: Can only be called by an EOA");

        // Ensure that deposit amount is greater than 2 ETH
        uint256 price = MarketController.getPriceEth(comptroller, token);
        uint256 deposited = price.mul(amount).div(1e18); //Calculated the deposited amount in ETH
        require(deposited >= 2e18, "Tank: Amount must be worth at least one Ether");

        // Get tokens from users and deposit them into Fuse
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        MarketController.supply(cToken, amount); // Deposit into Fuse

        // Mint tokens to the user
        uint256 exchangeRate = exchangeRateCurrent();
        uint256 mantissa = ERC20Upgradeable(token).decimals();
        _mint(msg.sender, amount.mul(exchangeRate).div(10**mantissa));
    }

    /** @dev Withdraw from the Tank  */
    function withdraw(uint256 amount) external blockLock(300) {
        // 300 blocks is about 1 hour
        require(msg.sender == tx.origin, "Tank: Can only be called by an EOA");

        // Calculate balance and ensure that withdrawal amount is less than or equal to it
        uint256 balance = balanceOfUnderlying(msg.sender);
        require(amount <= balance, "Tank: Balance too low");

        // Burn Tank tokens
        uint256 exchangeRate = exchangeRateCurrent();
        uint256 mantissa = ERC20Upgradeable(token).decimals();

        //_burn(msg.sender, amount.mul(10**(36 - mantissa)).div(exchangeRate));
        _burn(msg.sender, amount.mul(1e36).div(10**mantissa).div(exchangeRate));

        // Withdraw funds from the Tank and transfer them to the user
        withdrawFunds(amount); // Withdraw funds from money market
        IERC20(token).safeTransfer(msg.sender, amount); // Transfer the funds
    }

    /** 
        @dev Rebalance the Tank
        @param useWeth A boolean indicating whether to use wEth when swapping between tokens
    */
    function rebalance(bool useWeth) external pay blockLock(100) {
        // 100 blocks is about 20 mins
        require(msg.sender == tx.origin, "Tank: Can only be called by an EOA"); // Require that only an EO can call this method

        // Calculate profit and evaluate whether it is sufficient enough to trigger a rebalance
        (uint256 profit, bool profitSufficient) = getProfit(5e15); //0.5 percent

        // Calculate borrow balance divergence and evaluate whether it is sufficient enough to trigger a rebalance
        (uint256 divergence, bool idealGreater, bool divergenceSufficient) =
            getBorrowBalanceDivergence(15e16); //15%

        // Ensure that either the earned profit or borrow balance divergence is enough to trigger a rebalance
        require(divergenceSufficient || profitSufficient, "Tank: Cannot be rebalanced");

        // Take profit and supply it as collateral
        if (profitSufficient) takeProfit(profit, useWeth);
        // Repay debts or borrow more funds to match the ideal bororw balance
        if (divergenceSufficient) {
            if (idealGreater) borrow(divergence);
            else repay(divergence);
        }
    }

    /********************
     * Public Functions *
     ********************/
    /** @dev Get the Tank Token Exchange rate scaled by 1e18 */
    function exchangeRateCurrent() public returns (uint256) {
        uint256 supply = totalSupply();
        uint256 mantissa = ERC20Upgradeable(token).decimals();

        uint256 balance =
            MarketController.balanceOfUnderlying(cToken).mul(1e18).div(10**mantissa);

        // The initial exchange rate should be 1:1\
        if (balance == 0 || supply == 0) return 1e18;
        return balance.mul(1e18).div(supply); // Otherwise (balance / supply)
    }

    /** @dev Get a user's balance in underlying tokens */
    function balanceOfUnderlying(address account) public returns (uint256) {
        uint256 balance = balanceOf(account);
        uint256 exchangeRate = exchangeRateCurrent();

        return
            balance.mul(exchangeRate).mul(10**ERC20Upgradeable(token).decimals()).div(
                1e36
            );
    }

    /********************
     * Internal Functions *
     *********************/

    /** @dev Withdraw funds from Fuse while maintaining the collateral factor */
    function withdrawFunds(uint256 amount) internal {
        // Calculate the percentage of the balance that the amount represents
        uint256 totalSupplied = MarketController.balanceOfUnderlying(cToken);
        uint256 represents = amount.mul(1e18).div(totalSupplied);

        uint256 totalBorrowed =
            MarketController.borrowBalanceCurrent(comptroller, borrowing);

        // Use the percentage value to calculate the borrow balance due
        uint256 due = totalBorrowed.mul(represents).div(1e18);

        repay(due); // Repay the due amount
        MarketController.withdraw(cToken, amount); // Withdraw the tokens
    }

    /** @dev Withdraw from the yield source, repay debts, and swap profits */
    function takeProfit(uint256 profit, bool useWeth) internal {
        // Compare the current borrow balance to the last one
        uint256 borrowBalance = MarketController.borrowBalanceCurrent(comptroller, token);
        uint256 debt =
            borrowBalance > lastBorrowBalance ? borrowBalance - lastBorrowBalance : 0;

        YieldSourceController.withdraw(profit); // Withdraw profits from the yield source
        lastYieldSourceBalance = YieldSourceController.balanceOf();

        if (debt >= profit) {
            // If the debt >= profit, repay part of the loan using the entirety of the profit
            MarketController.repay(comptroller, borrowing, profit);
            return;
        } else if (profit > debt && debt > 0)
            // If the debt is nonzero but less than the profit, repay the debt using part of the profit
            MarketController.repay(comptroller, borrowing, debt);

        // Swap borrowed (earned) tokens to collateral tokens and supply it to Fuse
        MarketController.supply(cToken, swapProfit(useWeth, profit - debt));
    }

    /** @dev Swap profits from the borrowed asset to the supplied asset */
    function swapProfit(bool useWeth, uint256 amount) internal returns (uint256) {
        address[] memory path = new address[](useWeth ? 3 : 2); // The size of the path is based on
        path[0] = borrowing;

        // The size of the path is based on the useWeth parameter
        if (useWeth) {
            path[1] = WETH;
            path[2] = token;
        } else {
            path[1] = token;
        }

        IERC20(borrowing).approve(router, amount);

        // Swap tokens and return the output amount
        return
            IUniswapV2Router02(router).swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            )[useWeth ? 2 : 1]; // The location of the output amount in the returned array is based on the useWeth arg
    }

    /** 
        @dev Get the Tank's profits in the yield source and evaluate whether it is greater than a certain threshold
        @param threshold The percentage threshold for profits 
    */
    function getProfit(uint256 threshold)
        internal
        returns (uint256 profit, bool sufficient)
    {
        // Calculate the profit by subtracting the last balance from the current one
        profit = YieldSourceController.balanceOf().sub(lastYieldSourceBalance);

        // Using the percentage threshold, calculate the minimum profit needed to trigger a rebalance
        uint256 thresholdValue = lastYieldSourceBalance.mul(threshold).div(1e18);
        sufficient = profit > thresholdValue; // Identify whether the profit is sufficient enough to initiate a rebalance
    }

    /** 
        @dev Get the borrow balance divergence 
        @return divergence the borrow balance divergence
        @return idealGreater a boolean indicating whether the ideal balance is greater than the current one 
    */
    function getBorrowBalanceDivergence(uint256 threshold)
        internal
        returns (
            uint256 divergence,
            bool idealGreater,
            bool divergenceSufficient
        )
    {
        uint256 idealBorrowAmount = getIdealBorrowAmount(); // Get the ideal borrow balance
        idealGreater = idealBorrowAmount > lastBorrowBalance; // Identify whether the borrow balance is greater

        // Identify how much the borrow balance has diverged from the ideal borrow amount
        divergence = idealGreater ? idealBorrowAmount - lastBorrowBalance : !idealGreater
            ? lastBorrowBalance - idealBorrowAmount
            : 0;

        // Using the percentage threshold, identify whether the divergence is sufficient to initiate a rebalance
        uint256 borrowThreshold = lastBorrowBalance.mul(threshold).div(1e18);
        divergenceSufficient = divergence > borrowThreshold;
    }

    /** @dev Borrow a stable asset from Fuse and deposit it into the yield source */
    function borrow(uint256 borrowAmount) internal {
        MarketController.borrow(comptroller, borrowing, borrowAmount);
        lastBorrowBalance += borrowAmount;

        YieldSourceController.deposit(borrowAmount);
        lastYieldSourceBalance += borrowAmount;
    }

    /** @dev Withdraw a stable asset from the yield source and repay part of the loan */
    function repay(uint256 withdrawalAmount) internal {
        YieldSourceController.withdraw(withdrawalAmount);
        lastYieldSourceBalance -= withdrawalAmount;

        MarketController.repay(comptroller, borrowing, withdrawalAmount);
        lastBorrowBalance -= (withdrawalAmount);
    }

    /** @return the ideal borrow amount */
    function getIdealBorrowAmount() internal returns (uint256) {
        // Calculate the max borrow amount is USD
        uint256 usdBorrowAmount =
            MarketController.maxBorrowAmountUSD(cToken, comptroller, token);

        return
            MarketController
                .getTokensFromUsd(comptroller, borrowing, usdBorrowAmount) // Convert the usd borrow amount to borrowed tokens
                .mul(idealCollateralUtilization) // Multiply this value by the ideal collateral utilization factor
                .div(1e18);
    }
}
