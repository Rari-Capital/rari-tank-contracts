pragma solidity ^0.7.3;

/* Interfaces */
import {IKeep3r} from "../external/keep3r/IKeep3r.sol";
import {IFusePoolDirectory} from "../external/fuse/IFusePoolDirectory.sol";
import {AggregatorV3Interface} from "../external/chainlink/AggregatorV3Interface.sol";

/**
    @title FactoryStorage
    @dev Contains the state variables for both Factory contracts
*/
abstract contract FactoryStorage {
    /*************
     * Constants *
     *************/
    IKeep3r internal constant KPR = IKeep3r(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    IFusePoolDirectory internal constant DIRECTORY =
        IFusePoolDirectory(0x835482FE0532f169024d5E9410199369aAD5C77E);
    AggregatorV3Interface constant FASTGAS =
        AggregatorV3Interface(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);

    /*************
     * Variables *
     *************/
    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /** @dev An array containing the address of all tanks */
    address[] public tanks;

    /** @dev A map from an address to a boolean, indicating whether an address is a Tank */
    mapping(address => bool) public isTank;

    /** @dev Maps the token to a map from Comptroller to a map from implementation id to tank */
    mapping(address => mapping(address => mapping(uint256 => address))) public getTank;

    /** @dev Array of original implementations addresses */
    address[] public initialImplementations;

    /** @dev Maps the address of a Tank to its id */
    mapping(address => uint256) public idByTank;

    /** @dev Maps the implementation ID to the implementation address */
    mapping(uint256 => address) public implementationById;

    /** @dev Maps the implementation to its implementation ID */
    mapping(address => uint256) public idByImplementation;
}
