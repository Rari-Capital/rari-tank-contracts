pragma solidity 0.7.3;

abstract contract RariTankStorage {

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
}