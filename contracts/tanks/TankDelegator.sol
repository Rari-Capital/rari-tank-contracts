pragma solidity 0.7.3;

/* Storage */
import {TankStorage} from ".";

/* Interfaces */
import {ITankFactory} from "./interfaces/IRariFactory.sol";

contract TankDelegator is TankStorage {
    /*************
     * Variables *
     *************/
    /** 
        @dev The ID of the implementation contract
        Defining it here saves gas
    */
    uint256 public immutable implementationId;

    /***************
     * Constructor *
     ***************/
    constructor(
        address _token,
        address _comptroller,
        uint256 _implementationId
    ) {
        implementationId = _implementationId;
        factory = msg.sender;

        address implementation =
            ITankFactory(msg.sender).implementationById(_implementationId);

        delegateTo(
            implementation,
            abi.encodeWithSignature("initialize(address,address)", _token, _comptroller)
        );
    }

    /**********************
     * Fallback Functions *
     **********************/
    /** @dev Delegate calls to the implementation contract */
    fallback() external payable {
        require(msg.value == 0, "RariTankDelegator: Cannot send funds to contract");

        //Retrieve implementation address from factory contract
        address implementation =
            IRariTankFactory(factory).implementationById(implementationId);

        (bool success, ) = implementaiton.delegatecall(msg.data);

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

    recieve() external payable {}

    /********************
     * Internal Functions *
     *********************/
    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }
}
