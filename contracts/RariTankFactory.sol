pragma solidity ^0.7.3;

/* Contracts */
import {RariFundTank} from "./RariFundTank.sol";

/* Interfaces */
import {IRariTankFactory} from "./interfaces/IRariTankFactory.sol";

/* External */
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

    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /***************
     * Constructor *
    ***************/
    constructor(address _fundManager) {
        fundManager = _fundManager;
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
        @param cErc20Contract The underlying 
        @param comptroller The FusePool's comptroller
        @return The address of the new tank
    */
    function deployTank(address erc20Contract, address cErc20Contract, address comptroller) external override returns (address) {
        require(msg.sender == fundManager, "RariTankFactory: Must be called by the RariFundManager");

        address underlying = ICErc20(cErc20Contract).underlying();
        require(
            cErc20Contract != address(0) && underlying == erc20Contract,
            "RariTankFactory: Invalid CErc20 Contract"
        );

        (bool isListed,,) = IComptroller(comptroller).markets(cErc20Contract);
        require(isListed, "RariTankFactory: Unlisted CErc20Contract");

        RariFundTank tank = new RariFundTank();
        return address(tank);
    }
}