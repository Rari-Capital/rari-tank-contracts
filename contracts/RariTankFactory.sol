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
    @dev Deploys RariTankDelegator implementations
*/
contract RariTankFactory is IRariTankFactory, Ownable {

    /*************
    * Constants *
    *************/
    IKeep3r internal constant KPR = IKeep3r(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    /*************
    * Variables *
    *************/

    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /** @dev Maps the underlying token to a map from implementation to tank  */
    mapping(address => mapping(address => address)) private tankByImplementation;

    /** @dev Maps the address of an implementation to an array of tanks that use it */
    mapping(address => address[]) private tanksByImplementation;

    /** @dev Maps the underlying token to an array of tanks supporting it */
    mapping(address => address[]) private tanksByUnderlying;

    /*************
     * Modifiers *
    **************/
    modifier keep() {
        uint256 left = gasleft();
        require(KPR.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        KPR.receiptETH(msg.sender, left - gasleft());
    }

    /***************
     * Constructor *
    ***************/
    constructor(address _fusePoolDirectory) {
        fusePoolDirectory = _fusePoolDirectory;
    }

    /********************
    * External Functions *
    ********************/
    function newFusePoolDirectory(address _fusePoolDirectory) external {
        fusePoolDirectory = _fusePoolDirectory;
    }

    /**
    @dev Rebalance the tank
    */
    function rebalance(address tank) external override keep {
        IRariTank(tank).rebalance();
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
            implementation
        );

        address tankAddr = address(tank);

        tankByImplementation[erc20Contract][implementation] = tankAddr;
        tanksByImplementation[implementation].push(tankAddr);
        tanksByUnderlying[erc20Contract].push(tankAddr);

        return tankAddr;
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
        return tankByImplementation[erc20Contract][implementation];
    }
}