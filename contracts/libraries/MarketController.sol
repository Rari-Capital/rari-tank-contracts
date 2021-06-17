pragma solidity 0.7.3;

/* Interfaces */
import {ICErc20} from "../external/compound/ICErc20.sol";
import {IComptroller} from "../external/compound/IComptroller.sol";
import {IPriceFeed} from "../external/compound/IPriceFeed.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "../external/chainlink/AggregatorV3Interface.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
    @title MarketController
    @author Jet Jadeja <jet@rari.capital>
    @dev Handles interactions with a money market
    Note that this currently is setup for Fuse (and Compound)
*/
library MarketController {
    using SafeMath for uint256;

    /*************
     * Variables *
     *************/

    AggregatorV3Interface constant ETH_PRICEFEED =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /********************
     * Internal Functions *
     ********************/
    /** @dev Supply funds to the money market  */
    function supply(address cErc20, uint256 amount) internal {
        ICErc20 cToken = ICErc20(cErc20);

        // Approve underlying and mint tokens
        IERC20(cToken.underlying()).approve(cErc20, amount);
        require(cToken.mint(amount) == 0, "Tank: Failed to supply funds to Money Market");
    }

    /** @dev Withdraw funds from the market */
    function withdraw(address cErc20, uint256 amount) internal {
        require(
            ICErc20(cErc20).redeemUnderlying(amount) == 0,
            "Tank: Failed to withdraw funds from money market"
        );
    }

    /**  @dev Call the enterMarkets() function allowing you to start borrowing against the asset */
    function enterMarkets(address cErc20, address comptroller) internal {
        address[] memory cTokens = new address[](1);
        cTokens[0] = cErc20;
        require(
            IComptroller(comptroller).enterMarkets(cTokens)[0] == 0,
            "Tank: Failed to enter markets"
        );
    }

    /** 
        @dev Borrow from the money market
        @param token is used instead of a CErc20 address because we don't store the CERC20 address for borrowed assets
    */
    function borrow(
        address comptroller,
        address token,
        uint256 amount
    ) internal {
        uint256 error = getCErc20Contract(comptroller, token).borrow(amount);
        require(error == 0, "Tank: Failed to borrow");
    }

    /** @dev Repay a loan from the money market */
    function repay(
        address comptroller,
        address token,
        uint256 amount
    ) internal {
        ICErc20 cToken = getCErc20Contract(comptroller, token);
        IERC20(token).approve(address(cToken), amount);

        require(cToken.repayBorrow(amount) == 0, "Tank: Failed to repay loan");
    }

    /** @return the contract's balance in underlying tokens */
    function balanceOfUnderlying(address cErc20) internal returns (uint256) {
        return ICErc20(cErc20).balanceOfUnderlying(address(this));
    }

    /** @return the contract's borrowing balance (accounts for interest accrued) */
    function borrowBalanceCurrent(address comptroller, address token)
        internal
        returns (uint256)
    {
        return getCErc20Contract(comptroller, token).borrowBalanceCurrent(address(this));
    }

    /** @dev Get price mantissa of an asset in USDC */
    function getPrice(address comptroller, address token)
        internal
        view
        returns (uint256)
    {
        // Get price data
        uint256 price = getPriceEth(comptroller, token);
        (, int256 ethPrice, , , ) = ETH_PRICEFEED.latestRoundData();

        return price.mul(uint256(ethPrice)).div(1e12);
    }

    /** @dev Get the price mantissa of an asset in ETH */
    function getPriceEth(address comptroller, address token)
        internal
        view
        returns (uint256)
    {
        IPriceFeed priceFeed = IComptroller(comptroller).oracle();
        priceFeed.getUnderlyingPrice(getCErc20Contract(comptroller, token));
    }

    /** 
        @dev Convert a USD value to underlying tokens 
        @param amount The USD amount
    */
    function getTokensFromUsd(
        address comptroller,
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        return amount.mul(1e18).div(getPrice(comptroller, token));
    }

    /** @dev Get the max borrow amount in USD */
    function maxBorrowAmountUSD(
        address cToken,
        address comptroller,
        address token
    ) internal returns (uint256) {
        (, uint256 collateralFactor) = IComptroller(comptroller).markets(cToken);
        uint256 price = getPrice(comptroller, token);
        uint256 balance = ICErc20(cToken).balanceOfUnderlying(address(this));
        uint256 balanceUSD = balance.mul(price).div(1e18);

        return balanceUSD.mul(collateralFactor).div(1e18);
    }

    /** @return the address of the CErc20 contract given the Comptroller and underlying asset */
    function getCErc20Contract(address comptroller, address underlying)
        internal
        view
        returns (ICErc20)
    {
        return IComptroller(comptroller).cTokensByUnderlying(underlying);
    }
}
