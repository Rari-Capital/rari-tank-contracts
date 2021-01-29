pragma solidity ^0.7.3;

/* External */
import {IRariFundManager} from "../external/rari/IRariFundManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
    @title RariPoolController
    @author Jet Jadeja <jet@rari.capital>
    @dev Handles interactions with the Rari Stable Pool
*/
library RariPoolController {
    /* CONSTANTS */
    address constant RARI_FUND_MANAGER = 0xC6BF8C8A55f77686720E0a88e2Fd1fEEF58ddf4a;

    /**
        @dev Deposit into the Rari Stable Pool
        @param currencyCode The symbol of the ERC20 Contract
        @param erc20Contract The address of the ERC20 Contract
        @param amount The amount being deposited
    */
    function deposit(string memory currencyCode, address erc20Contract, uint256 amount) internal {
        IERC20(erc20Contract).approve(RARI_FUND_MANAGER, amount);
        IRariFundManager(RARI_FUND_MANAGER).deposit(currencyCode, amount);
    }

    /**
        @dev Withdraw from the Rari Stable Pool
        @param currencyCode The symbol of the ERC20 Contract
        @param amount The amount being withdrew
    */
    function withdraw(string memory currencyCode, uint256 amount) internal {
        IRariFundManager(RARI_FUND_MANAGER).withdraw(currencyCode, amount);
    }

    /** @return The contract's USD balance in the Rari Stable Pool, scaled by 1e18 */
    function balanceOf() internal returns (uint256) {
        IRariFundManager(RARI_FUND_MANAGER).balanceOf(address(this));
    }
}