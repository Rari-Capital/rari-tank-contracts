pragma solidity ^0.7.3;

/* Contracts */
import {RariTankDelegator} from "./RariTankDelegator.sol";

/* Interfaces */
import {IRariTankFactory} from "./interfaces/IRariTankFactory.sol";
import {IRariTank} from "./interfaces/IRariTank.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICErc20} from "./external/compound/ICErc20.sol";
import {IComptroller} from "./external/compound/IComptroller.sol";
import {IFusePoolDirectory} from "./external/fuse/IFusePoolDirectory.sol";

import {IKeep3r} from "./external/keep3r/IKeep3r.sol";

/**
    @title RariTankFactory
    @author Jet Jadeja
    @dev Deploys RariFundTank implementations
*/
contract RariTankFactory is IRariTankFactory, Ownable {

    /*************
    * Constants *
    *************/
    IKeep3r internal constant KPR = IKeep3r(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    /*************
    * Variables *
    *************/

    /** @dev The address of the RariDataProvider */
    address private dataProvider;

    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /** @dev The address of the rebalancer */
    address private rebalancer;

    /** @dev Maps the underlying token to a map from implementation to tank  */
    mapping(address => mapping(address => address)) private tanksByImplementation;

    /** @dev Maps the underlying token to an array of tanks supporting it */
    mapping(address => address[]) private tanksByUnderlying;

    /*************
     * Modifiers *
    **************/
    modifier keep() {
        require(KPR.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        KPR.worked(msg.sender);
    }

    /***************
     * Constructor *
    ***************/
    constructor(address _dataProvider, address _fusePoolDirectory, address _rebalancer) {
        dataProvider = _dataProvider;
        fusePoolDirectory = _fusePoolDirectory;
        rebalancer = _rebalancer;
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

        RariTankDelegator tank = new RariTankDelegator(
            erc20Contract, 
            comptroller, 
            address(this),
            dataProvider,
            implementation
        );

        tanksByImplementation[erc20Contract][implementation] = address(tank);
        tanksByUnderlying[erc20Contract].push(address(tank));

        return erc20Contract;
    }

    /*****************
    * View Functions *
    ******************/
    /** 
        @dev Given a token
        @return a list of tanks that support it 
    */
    function getTanksByUnderlying(address erc20Contract) external view returns (address[] memory) {
        address[] memory tanks = tanksByUnderlying[erc20Contract];
        return tanks;
    }

    /** 
        @dev Given an token and implementation address 
        @return tank that supports the token and uses the implementation contract
    */
    function getTankByImplementation(address erc20Contract, address implementation) external view returns (address) {
        return tanksByImplementation[erc20Contract][implementation];
    }

    function rebalance(address tank) external {
        require(msg.sender == rebalancer, "RariTankFactory: Must be called by the rebalancer");
        IRariTank(tank).rebalance();
    }
}