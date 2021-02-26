pragma solidity 0.7.3;

/* Interfaces */
import {IRariDataProvider} from "./interfaces/IRariDataProvider.sol";

import {ICErc20} from "./external/compound/ICErc20.sol";
import {IPriceFeed} from "./external/compound/IPriceFeed.sol";
import {IComptroller} from "./external/compound/IComptroller.sol";

/* Libaries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
    @title RariDataProvider
    @author Jet Jadeja <jet@rari.capital>
    @dev Provides price data and executes price-related calculations
*/
contract RariDataProvider is IRariDataProvider {
    using SafeMath for uint256;

    /********************
    * External Functions *
    ********************/

    /** @return The current borrow balance of the user */
    function borrowBalanceCurrent(ICErc20 cToken) external override returns (uint256) {
        return cToken.borrowBalanceCurrent(msg.sender);
    }

    /** 
        @dev Given a certain amount of underlying tokens, use the exchange rate to calculate the equivalent amount in CErc20 tokens
    */
    function convertUnderlyingToCErc20(
        ICErc20 cToken, 
        uint256 amount
    )
        external 
        override 
        returns (uint256) 
    {
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        return amount.mul(1e18).div(exchangeRate);
    }

    /** 
        @dev Given a certain amount of cErc20 tokens, use the exchange rate to calculate the equivalent amount in underlying tokens
    */
    function convertCErc20ToUnderlying(
        ICErc20 cToken, 
        uint256 amount
    ) 
        external 
        override 
        returns (uint256) 
    {
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        return amount.mul(exchangeRate).div(1e18);
    }


    /**
        @param amount The amount of underlying tokens
        @return The maximum USD that can be borrowed, scaled by 1e18
    */
    function maxBorrowAmountUSD(
        IComptroller comptroller, 
        address cErc20Contract, 
        uint256 amount
    ) 
        external 
        override 
        returns (uint256) 
    {
        IPriceFeed priceFeed = comptroller.oracle();

        (, uint256 collateralFactor, ) = comptroller.markets(cErc20Contract);
        uint256 price = _getUnderlyingPrice(priceFeed, cErc20Contract);
        uint256 balanceUSD = amount.mul(price).div(1e18);

        return balanceUSD.mul(collateralFactor).div(1e18);
    }

    /** @return The price of the underlying asset */
    function getUnderlyingPrice(
        IComptroller comptroller, 
        address cErc20Contract
    ) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return _getUnderlyingPrice(comptroller.oracle(), cErc20Contract);
    }

    /** @dev Given a certain USD amount (scaled by 1e18), use the price feed to calculate the equivalent value in underlying tokens */
    function convertUSDToUnderlying(
        IComptroller comptroller, 
        address cErc20Contract, 
        uint256 amount
    ) 
        external 
        view 
        override 
        returns (uint256) 
    {
        uint256 price = _getUnderlyingPrice(comptroller.oracle(), cErc20Contract);
        return amount.mul(1e18).div(price);
    }

    /********************
    * Internal Functions *
    ********************/

    /** @return The price of the underlying asset */
    function _getUnderlyingPrice(
        IPriceFeed priceFeed, 
        address cErc20Contract
    ) 
        internal 
        view 
        returns (uint256)
    {
        return priceFeed.getUnderlyingPrice(cErc20Contract);
    }
}