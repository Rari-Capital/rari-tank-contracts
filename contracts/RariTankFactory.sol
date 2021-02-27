pragma solidity ^0.7.3;

/* Contracts */
import {RariTankDelegate} from "./tanks/RariTankDelegate.sol";

/* Interfaces */
import {IRariTankFactory} from "./interfaces/IRariTankFactory.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICErc20} from "./external/compound/ICErc20.sol";
import {IComptroller} from "./external/compound/IComptroller.sol";
import {IFusePoolDirectory} from "./external/fuse/IFusePoolDirectory.sol";

/**
    @title RariTankFactory
    @author Jet Jadeja
    @dev Deploys RariFundTank implementations
*/
contract RariTankFactory is IRariTankFactory, Ownable {
    /*************
    * Variables *
    *************/

    /** @dev The address of the RariDataProvider */
    address private dataProvider;

    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /** @dev Maps the underlying token to a map from implementation to token  */
    mapping(address => mapping(address => address)) private tanksByImplementation;

    /** @dev Maps the underlying token to an array of tanks supporting it */
    mapping(address => address) private tanksByUnderlying;

    /***************
     * Constructor *
    ***************/
    constructor(address _dataProvider, address _fusePoolDirectory) {
        dataProvider = _dataProvider;
        fusePoolDirectory = _fusePoolDirectory;
    }

    /********************
    * External Functions *
    ********************/
    function newFusePoolDirectory(address _fusePoolDirectory) external {
        fusePoolDirectory = _fusePoolDirectory;
    }

    /** 
        @dev Deploy a new tank
        @param erc20Contract The underlying asset
        @param comptroller The FusePool's comptroller
        @param implementation The tank's delegate contract
        @return The address of the new tank
    */
    function deployTank(address erc20Contract, address comptroller, address implementation) external override returns (address) {
        // Input validation
        require(IFusePoolDirectory(fusePoolDirectory).poolExists(comptroller), "RariTankFactory: Invalid Pool");
        //RariTankDelegate tank = new RariFundTank(erc20Contract, comptroller, fundManager, dataProvider);
        return erc20Contract;
    }
}