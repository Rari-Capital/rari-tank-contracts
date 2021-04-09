pragma solidity 0.7.3;

/* Interfaces */
import {IKeep3r} from "../external/keep3r/IKeep3r.sol";
import {IUniswapV2Router02} from "../external/uniswapv2/IUniswapV2Router.sol";

abstract contract RariTankStorage {
    /*************
     * Variables *
     *************/
    /** @dev The address of the ERC20 token supported by the tank */
    address public token;

    /** @dev The address of the CErc20 Contract representing the tank's underlying token */
    address public cToken;

    /** @dev The address of the ERC20 contract that will be borrowed */
    address public borrowing;

    /** @dev The symbol of the asset being borrowed */
    string public borrowSymbol;

    /** @dev The UniswapV2 Router */
    IUniswapV2Router02 internal router;

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
