pragma solidity 0.7.3;

/**
    @title TankStorage
    @author Jet Jadeja <jet@rari.capital>
    @dev Manages state data for Tank contracts
*/
abstract contract TankStorage {
    /*************
     * Variables *
     *************/
    /** @dev The address of the ERC20 token that users deposit/earn yield on in the Tank */
    address public token;

    /** @dev The address of the Fuse fToken that represents the Tank's underlying balance */
    address public cToken;

    /** @dev The token that the Tank borrows and deposits into a yield source */
    address public borrowing;

    /** @dev Address of the TankFactory contract */
    address internal factory;

    /** @dev Address of the FusePool Comptroller token */
    address internal comptroller;

    /** @dev Initializable */
    bool internal initalized;
}
