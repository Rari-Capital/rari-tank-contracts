pragma solidity ^0.7.3;

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/* External */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICErc20} from "../external/compound/ICErc20.sol";
import {IComptroller} from "../external/compound/IComptroller.sol";
import {IPriceFeed} from "../external/compound/IPriceFeed.sol";

/**
    @title FusePoolController
    @author Jet Jadeja <jet@rari.capital>, David Lucid <david@rari.capital>
    @dev Handles interactions with Fuse
*/
library FusePoolController {
    using SafeMath for uint256;

    /********************
    * Internal Functions *
    ********************/

    /** @dev Deposit collateral into Fuse */
    function deposit(
        address comptrollerContract, 
        address cErc20Contract, 
        uint256 amount
    ) 
        internal 
    {
        ICErc20 cToken = ICErc20(cErc20Contract);
        IComptroller comptroller = IComptroller(comptrollerContract);

        // Approve underlying and mint cTokens
        IERC20(cToken.underlying()).approve(cErc20Contract, amount);
        uint256 error = cToken.mint(amount);    
        require(error == 0, "CErc20: Failed to deposit underlying");

        // Enter markets
        address[] memory cTokens = new address[](1);
        cTokens[0] = cErc20Contract;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);

        require(errors[0] == 0, "Comptroller: Failed to enter markets");
    }

    /** @dev Withdraw from Fuse */
    function withdrawal(address cErc20Contract, uint256 amount) internal {
        uint256 error = ICErc20(cErc20Contract).redeemUnderlying(amount);
        require(error == 0, "CErc20: Failed to redeem underlying");
    }

    /** @dev Borrow a certain amount from Fuse */
    function borrow(address cErc20Contract, uint256 amount) internal {
        uint256 error = ICErc20(cErc20Contract).borrow(amount);
        require(error == 0, "CErc20: Failed to borrow underlying");
    }

    /** @dev Repay a Fuse loan */
    function repay(address cErc20Contract, uint256 amount) internal {
        ICErc20 cToken = ICErc20(cErc20Contract);
        IERC20(cToken.underlying()).approve(cErc20Contract, amount);

        uint256 error = ICErc20(cErc20Contract).repayBorrow(amount);
        require(error == 0, "CErc20: Repay error");
    }

    /** @dev Get the contract's underlying balance */
    function balanceOfUnderlying(address cErc20Contract) internal returns (uint256) {
        return ICErc20(cErc20Contract).balanceOfUnderlying(address(this));
    }

    /** @dev Get the contract's current borrow balance */
    function borrowBalanceCurrent(address cErc20Contract) internal returns (uint256) {
        return ICErc20(cErc20Contract).borrowBalanceCurrent(address(this));
    }
}