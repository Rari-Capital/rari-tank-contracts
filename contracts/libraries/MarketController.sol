pragma solidity 0.7.3;

/* Interfaces */
import {ICErc20} from "../external/compound/ICErc20.sol";
import {IComptroller} from "../external/compound/IComptroller.sol";
import {IPriceFeed} from "../external/compound/IPriceFeed.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "../external/chainlink/AggregatorV3Interface.sol";

/**
    @title MarketController
    @author Jet Jadeja <jet@rari.capital>
    @dev Handles interactions with a money market
    Note that this currently is setup for Fuse (and Compound)
*/
library MarketController {
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
        @param underlying is used instead of a CErc20 address because we don't store the ERC20 address for borrowed assets
    */
    function borrow(
        address comptroller,
        address underlying,
        uint256 amount
    ) internal {
        uint256 error = getCErc20Contract(comptroller, underlying).borrow(amount);
        require(error == 0, "Tank: Failed to borrow");
    }

    /** @dev Repay a loan from the money market */
    function repay(
        address comptroller,
        address underlying,
        uint256 amount
    ) internal {
        ICErc20 cToken = getCErc20Contract(comptroller, underlying);
        IERC20(underlying).approve(address(cToken), amount);

        require(cToken.repayBorrow(amount) == 0, "Tank: Failed to repay loan");
    }

    /** 
        @return the address of the CErc20 contract given the Comptroller and underliying
    */
    function getCErc20Contract(address comptroller, address underlying)
        internal
        view
        returns (ICErc20)
    {
        return IComptroller(comptroller).cTokensByUnderlying(underlying);
    }
}