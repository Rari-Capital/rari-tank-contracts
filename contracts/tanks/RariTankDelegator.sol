pragma solidity 0.7.3;

/* Interfaces */
import {RariTankStorage} from "./RariTankStorage.sol";
import {IRariTankFactory} from "../interfaces/IRariTankFactory.sol";

/**
    @title RariTankDelegator
    @author Jet Jadeja <jet@rari.capital>
    @dev Uses the RariTankDelegate to handle interactions with Fuse
*/
contract RariTankDelegator is RariTankStorage {
    /*************
     * Variables *
     *************/
    /** @dev The ID of the implementation contract */
    uint256 public immutable implementationId;

    /***************
     * Constructor *
     ***************/
    constructor(
        address _token,
        address _comptroller,
        address _router,
        uint256 _implementationId
    ) {
        implementationId = _implementationId;

        // Ideally we could use getImplementation(), however since implementationId is immutable, we cannot use it in the constructor
        address implementation =
            IRariTankFactory(msg.sender).implementationById(_implementationId);

        delegateTo(
            implementation,
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                _token,
                _comptroller,
                _router,
                msg.sender
            )
        );
    }

    /**********************
     * Fallback Functions *
     **********************/

    fallback() external payable {
        require(msg.value == 0, "RariTankDelegator: Cannot send funds to contract");

        (bool success, ) = getImplementation().delegatecall(msg.data);

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

    function getImplementation() internal view returns (address) {
        return IRariTankFactory(factory).implementationById(implementationId);
    }
}
