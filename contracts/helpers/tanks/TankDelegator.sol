pragma solidity 0.7.3;

/* Storage */
import {TankStorage} from "./TankStorage.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";

/* Interfaces */
import {ITankFactory} from "../../interfaces/ITankFactory.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract TankDelegator is TankStorage, ERC20Upgradeable {
    /***************
     * Constructor *
     ***************/
    function initialize(
        address _token,
        address _comptroller,
        uint256 _implementationId
    ) external {
        require(!initalized, "Tank: Initialization has already occured");

        implementationId = _implementationId;
        factory = msg.sender;

        address implementation =
            ITankFactory(msg.sender).implementationById(_implementationId);

        delegateTo(
            implementation,
            abi.encodeWithSignature("initialize(address,address)", _token, _comptroller)
        );

        initalized = true;
    }

    /**********************
     * Fallback Functions *
     **********************/
    /** @dev Delegate calls to the implementation contract */
    fallback() external payable {
        require(msg.value == 0, "RariTankDelegator: Cannot send funds to contract");

        //Retrieve implementation address from factory contract
        address implementation =
            ITankFactory(factory).implementationById(implementationId);

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

    /********************
     * Internal Functions *
     *********************/
    /** @dev Make a delegatecall to a certain contract and deliver the returned data  */
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
