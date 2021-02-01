pragma solidity 0.7.3;

/* Interfaces */
import {IRariFundTank} from "./interfaces/IRariFundTank.sol";
import {IRariTankFactory} from "./interfaces/IRariTankFactory.sol";
import {IRariFundManager} from "./interfaces/IRariFundManager.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/* External */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
    @title RariFundManager
    @author Jet Jadeja <jet@rari.capital>
    @dev Manages deposits, withdrawals, and rebalances to and from the tank contracts 
*/
contract RariFundManager is IRariFundManager, Ownable {
    using SafeERC20 for IERC20;
    /*************
     * Variables *
     *************/

    /** @dev The address of the RariTankFactory */
    address private factory;

    /** @dev Maps ERC20 contracts to their corresponding tank  */
    mapping(address => address) private underlyingToTanks;

    /********************
    * External Functions *
    ********************/

    /** @dev Set a new factory contract */
    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /** 
        @dev Deploy a new tank
        @param cErc20Contract The address of the CERC20 contract representing the token that the tank will support
        @param comptroller The address of the Comptroller contract of the FusePool that the token belongs too
    */
    function deployTank(
        address erc20Contract, 
        address cErc20Contract, 
        address comptroller
    ) 
        external 
        returns (address tank) 
    {
        require(underlyingToTanks[erc20Contract] == address(0), "RariFundManager: Tank supporting this asset already exists");
        tank = IRariTankFactory(factory).deployTank(erc20Contract, cErc20Contract, comptroller);
        underlyingToTanks[erc20Contract] = tank;
    }

    function deposit(address erc20Contract, uint256 amount) external override {
        require(erc20Contract != address(0), "RariFundManager: Invalid currency address");
        address tankContract = underlyingToTanks[erc20Contract];
        require(tankContract != address(0), "RariFundManager: Tank does not exist");

        IERC20(erc20Contract).safeTransferFrom(msg.sender, tankContract, amount);
        IRariFundTank(tankContract).deposit(msg.sender, amount);

    }
    function withdraw(address erc20Contract, uint256 amount) external override {}

    /** 
        @dev Execute a rebalance on a tank
        @param erc20Contract The address of the ERC20 Contract supported by the tank
    */
    function rebalance(address erc20Contract) external override {}


    /********************
    * View Functions *
    ********************/

    /**
        @param erc20Contract The address of the ERC20 Contract supported by the tank
        @return The address of the tank that supports the ERC20 Contract
    */
    function getTank(address erc20Contract) external view returns (address) {
        return underlyingToTanks[erc20Contract];
    }
}