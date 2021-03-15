pragma solidity 0.7.3;

/* Interfaces */
import {IRariDataProvider} from "./interfaces/IRariDataProvider.sol";

import {ICErc20} from "./external/compound/ICErc20.sol";
import {IPriceFeed} from "./external/compound/IPriceFeed.sol";
import {IComptroller} from "./external/compound/IComptroller.sol";

import {AggregatorV3Interface} from "./external/chainlink/AggregatorV3Interface.sol";

/* Libaries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
    @title RariDataProvider
    @author Jet Jadeja <jet@rari.capital>
    @dev Provides price data and executes price-related calculations
*/
contract RariDataProvider is IRariDataProvider {
    using SafeMath for uint256;

    /*************
    * Variables *
    *************/

    AggregatorV3Interface ETH_PRICEFEED = AggregatorV3Interface(
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );

    /********************
    * External Functions *
    ********************/

    /** @return The current borrow balance of the user */
    function borrowBalanceCurrent(address comptroller, address underlying) external override returns (uint256) {
        return getCErc20Contract(comptroller, underlying)
            .borrowBalanceCurrent(msg.sender);
    }

    /** 
        @dev Given a certain amount of underlying tokens, use the exchange rate to calculate the equivalent amount in CErc20 tokens
    */
    function convertUnderlyingToCErc20(
        address comptroller,
        address underlying, 
        uint256 amount
    )
        external 
        override 
        returns (uint256) 
    {
        uint256 exchangeRate = getCErc20Contract(comptroller, underlying)
            .exchangeRateCurrent();
        return amount.mul(1e18).div(exchangeRate);
    }

    /** 
        @dev Given a certain amount of cErc20 tokens, use the exchange rate to calculate the equivalent amount in underlying tokens
    */
    function convertCErc20ToUnderlying(
        address comptroller, 
        address underlying, 
        uint256 amount
    ) 
        external 
        override 
        returns (uint256) 
    {
        uint256 exchangeRate = getCErc20Contract(comptroller, underlying)
            .exchangeRateCurrent();
        return amount.mul(exchangeRate).div(1e18);
    }


    /**
        @param amount The amount of underlying tokens
        @return The maximum USD that can be borrowed, scaled by 1e18
    */
    function maxBorrowAmountUSD (
        address comptrollerContract, 
        address underlying,
        uint256 amount
    ) 
        external
        view
        override 
        returns (uint256) 
    {
        IComptroller comptroller = IComptroller(comptrollerContract);
        address cErc20Contract = address(comptroller.cTokensByUnderlying(underlying));

        (, uint256 collateralFactor) = comptroller.markets(cErc20Contract);
        uint256 price = _getUnderlyingPrice(comptrollerContract, underlying);
        uint256 balanceUSD = amount.mul(price).div(1e18);

        return balanceUSD.mul(collateralFactor).div(1e18);
    }

    function getUnderlyingInEth(
        address comptroller, 
        address underlying
    ) 
        external
        view 
        override
        returns (uint256) 
        {
            return _getUnderlyingInEth(comptroller, underlying);
        }

    /** @return The price of the underlying asset in USD */
    function getUnderlyingPrice(
        address comptroller,
        address underlying
    ) 
        external 
        view 
        override
        returns (uint256) 
    {
        return _getUnderlyingPrice(comptroller, underlying);
    }

    /** @dev Given a certain USD amount (scaled by 1e18), use the price feed to calculate the equivalent value in underlying tokens */
    function convertUSDToUnderlying(
        address comptroller, 
        address underlying, 
        uint256 amount
    ) 
        external 
        view 
        override 
        returns (uint256) 
    {
        uint256 price = _getUnderlyingPrice(comptroller, underlying);
        return amount.mul(1e18).div(price);
    }

    /********************
    * Internal Functions *
    ********************/

    /** @dev Return the price of the underlying asset relative to ETH */
    function _getUnderlyingInEth(
        address comptrollerContract,
        address underlying
    ) internal view returns (uint256) {
        IPriceFeed priceFeed = IPriceFeed(
            IComptroller(comptrollerContract).oracle()
        );
        ICErc20 cErc20 = getCErc20Contract(comptrollerContract, underlying);

        return priceFeed
            .getUnderlyingPrice(cErc20);
    }

    /** @return The price of the underlying asset */
    function _getUnderlyingPrice(
        address comptrollerContract, 
        address underlying
    ) 
        internal 
        view 
        returns (uint256)
    {
        uint256 price = _getUnderlyingInEth(comptrollerContract, underlying);
        (, int256 ethPrice, , , ) = ETH_PRICEFEED.latestRoundData();
        
        return price
            .mul(uint256(ethPrice))
            .div(1e12);
    }

    /** 
        @dev Given a comptroller and ERC20 token
        @return the address of the CErc20 contract representing the ERC20 token
    */
     function getCErc20Contract(address comptroller, address underlying) internal view returns (ICErc20) {
        return IComptroller(comptroller).cTokensByUnderlying(underlying);
     }
}