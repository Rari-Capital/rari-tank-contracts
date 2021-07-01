pragma solidity 0.7.3;

/* Interfaces */
import {IKeep3r} from "../../external/keep3r/IKeep3r.sol";
import {AggregatorV3Interface} from "../../external/chainlink/AggregatorV3Interface.sol";

/**
    @title TankFactory
    @author Jet Jadeja <jet@rari.capital>
    @dev Manages state data for the TankFactory
*/
abstract contract TankFactoryStorage {
    /*************
     * Variables *
     *************/

    /** @dev A boolean indicating whether the registration of new Tanks are available to everyone */
    bool public canDeploy;

    /** @dev An array containing all Tanks */
    address[] public tanks;

    /** @dev Array of original implementations addresses */
    address[] public initialImplementations;

    /** @dev Maps implementation ID to implementation address */
    mapping(uint256 => address) public ownerByImplementation;

    /** @dev Maps the address of a Tank to its id */
    mapping(address => uint256) public idByTank;

    /** @dev Maps the implementation ID to the implementation address */
    mapping(uint256 => address) public implementationById;

    /** @dev Maps the implementation to its implementation ID */
    mapping(address => uint256) public idByImplementation;

    /**********
     * Events *
     **********/

    /** @dev Emitted when a new implementation has been registered */
    event NewImplementation(uint256 id, address implementation);

    /** @dev Emitted when a Tank is rebalanced */
    event Rebalance(address indexed tank);

    /** @dev Emitted when an implementation has been upgraded */
    event ImplementationUpgraded(uint256 indexed id, address indexed implementation);

    /** @dev Emitted when a new Tank has been created */
    event NewTank(address tank, bytes indexed input, uint256 indexed id);

    /** @dev Emitted when the owner of an implementation is updated */
    event ImplementationOwnerTransferred(uint256 indexed id, address indexed newOwner);
}
