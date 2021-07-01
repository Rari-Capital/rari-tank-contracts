pragma solidity 0.7.3;

/* Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRariFundManager} from "../external/rari/IRariFundManager.sol";

/**
    @title YieldSourceController
    @author Jet Jadeja <jet@rari.capital>
    @dev Handles interactions with the yield source
*/
library YieldSourceController {
    /* CONSTANTS */

    /** @dev The token symbol for DAI */
    string constant SYMBOL = "DAI";

    address constant token = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /** @dev The address of the DAI Pool's Rari Fund Manager, an interface for handling deposits and withdrawals */
    IRariFundManager constant RARI_FUND_MANAGER =
        IRariFundManager(0xB465BAF04C087Ce3ed1C266F96CA43f4847D9635);

    /** @dev Deposit tokens into the yield source */
    function deposit(uint256 amount) internal {
        IERC20(token).approve(address(RARI_FUND_MANAGER), amount);
        RARI_FUND_MANAGER.deposit(SYMBOL, amount);
    }

    /** @dev Withdraw tokens */
    function withdraw(uint256 amount) internal {
        RARI_FUND_MANAGER.withdraw(SYMBOL, amount);
    }

    /** @return the balance of tokens in the yield source */
    function balanceOf() internal returns (uint256) {
        return RARI_FUND_MANAGER.balanceOf(address(this));
    }
}
