pragma solidity ^0.7.3;

/* Contracts */
import {RariFundTank} from "./RariFundTank.sol";

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
    
    /** @dev The address of the RariFundManager */
    address private fundManager;

    /** @dev The address of the RariDataProvider */
    address private dataProvider;

    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /***************
     * Constructor *
    ***************/
    constructor(address _fundManager, address _dataProvider, address _fusePoolDirectory) {
        fundManager = _fundManager;
        dataProvider = _dataProvider;
        fusePoolDirectory = _fusePoolDirectory;
    }

    /********************
    * External Functions *
    ********************/
    function newFundManager(address _fundManager) external onlyOwner {
        fundManager = _fundManager;
    }

    function newFusePoolDirectory(address _fusePoolDirectory) external {
        fusePoolDirectory = _fusePoolDirectory;
    }

    /** 
        @dev Deploy a new tank
        @param erc20Contract The underlying asset
        @param comptroller The FusePool's comptroller
        @return The address of the new tank
    */
    function deployTank(address erc20Contract, address comptroller) external override returns (address) {
        // Input validation
        require(msg.sender == fundManager, "RariTankFactory: Must be called by the RariFundManager");
        require(IFusePoolDirectory(fusePoolDirectory).poolExists(comptroller), "RariTankFactory: Invalid Pool");
        RariFundTank tank = new RariFundTank(erc20Contract, comptroller, fundManager, dataProvider);
        return address(tank);
    }
}