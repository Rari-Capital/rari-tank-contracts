pragma solidity 0.7.3;

/* Interfaces */
import {RariTankStorage} from "./tanks/RariTankStorage.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
    @title RariTankDelegator
    @author Jet Jadeja <jet@rari.capital>
    @dev Uses the RariTankDelegate to handle interactions with Fuse
*/
contract RariTankDelegator is RariTankStorage, ERC20Upgradeable {

    /*************
     * Variables *
    *************/
    /** @dev The address of the tank implementation contract */
    address public implementation;

    /***************
     * Constructor *
    ***************/
    constructor(
        address _token,
        address _comptroller,
        address _dataProvider, 
        address _implementation
    ) {
        implementation = _implementation;

        delegateTo(
            implementation, 
            abi.encodeWithSignature(
                "initialize(address,address,address)", 
                _token, 
                _comptroller, 
                _dataProvider
            )
        );
    }

    fallback () external payable {
        require(msg.value == 0, "RariTankDelegator: Cannot send funds to contract");
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    receive() external payable {}
}