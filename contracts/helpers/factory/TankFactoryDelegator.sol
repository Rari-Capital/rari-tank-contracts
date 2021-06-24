pragma solidity 0.7.3;

/* Storage */
import {TankFactoryStorage} from "./TankFactoryStorage.sol";

/* Interfaces */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
    @title Factory Delegator
    @author Jet Jadeja <jet@rari.capital>
    @dev Serves as a proxy factory contract
*/
contract FactoryDelegator is TankFactoryStorage, Ownable {
    /*************
     * Variables *
     *************/
    /** @dev The address of the factory implementation contract */
    address public implementation;

    /***************
     * Constructor *
     ***************/
    constructor(address _implementation) Ownable() {
        implementation = _implementation;
    }

    /**********************
     * Fallback Functions *
     **********************/
    fallback() external payable {
        require(msg.value == 0, "RariTankDelegator: Cannot send funds to contract");
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }

    receive() external payable {}

    /**********************
     * External Functions *
     **********************/
    /** @dev Upgrade the proxy contract's implementation address */
    function upgradeProxy(address _implementation) external onlyOwner {
        implementation = _implementation;
    }
}
