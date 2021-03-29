pragma solidity 0.7.3;

/* Interfaces */
import {IKeep3r} from "../external/keep3r/IKeep3r.sol";
import {IUniswapV2Router02} from "../external/uniswapv2/IUniswapV2Router.sol";

abstract contract RariTankStorage {

    /*************
    * Constants *
    *************/
    address internal constant BORROWING = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    string internal constant BORROWING_SYMBOL = "DAI";
    IUniswapV2Router02 internal constant ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IKeep3r internal constant KPR = IKeep3r(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    /*************
     * Variables *
    *************/
    /** @dev The address of the ERC20 token supported by the tank */
    address public token;

    /** @dev The address of the CErc20 Contract representing the tank's underlying token */
    address public cToken;

    /** @dev The address of the RariTankFactory */
    address internal factory;

    /** @dev The address of the FusePool Comptroller */
    address internal comptroller;

    /** @dev The tank's borrow balance */
    uint256 internal borrowBalance;

    /** @dev The tank's stable pool balance */
    uint256 internal yieldPoolBalance;

    /** @dev Initialized */
    bool internal initialized;

    /** @dev ETH that has been paid to Keep3rs for gas */
    uint256 internal paid;

}