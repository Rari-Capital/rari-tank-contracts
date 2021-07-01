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
    /** @dev Address of the factory contract */
    address public factory;

    /** @dev The ID of the implementation contract */
    uint256 public implementationId;
}
