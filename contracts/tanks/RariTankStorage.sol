pragma solidity 0.7.3;

import {IUniswapV2Router02} from "../external/uniswapv2/IUniswapV2Router.sol";

abstract contract RariTankStorage {

    /*************
    * Constants *
    *************/
    address internal constant BORROWING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string internal constant BORROWING_SYMBOL = "USDC";
    IUniswapV2Router02 internal constant ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /*************
     * Variables *
    *************/
    /** @dev The address of the ERC20 token supported by the tank */
    address public token;

    /** @dev The address of the CErc20 Contract representing the tank's underlying token */
    address public cToken;

    /** @dev The address of the RariFundManager */
    address internal fundManager;

    /** @dev The address of the RariDataProvider */
    address internal dataProvider;

    /** @dev The address of the FusePool Comptroller */
    address internal comptroller;

    /** @dev A count of undeposited funds */
    uint256 internal dormant;

    /** @dev The tank's borrow balance */
    uint256 internal borrowBalance;

    /** @dev The tank's stable pool balance */
    uint256 internal stablePoolBalance;

    /** @dev Initialized */
    bool internal initialized;

    /** @dev ETH that has been paid to Keep3rs for gas */
    uint256 internal paid;

}