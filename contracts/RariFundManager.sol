pragma solidity 0.7.3;

/* Interfaces */
import {IRariFundTank} from "./interfaces/IRariFundTank.sol";
import {IRariTankFactory} from "./interfaces/IRariTankFactory.sol";
import {IRariFundManager} from "./interfaces/IRariFundManager.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/* External */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
    @title RariFundManager
    @author Jet Jadeja <jet@rari.capital>
    @dev Manages deposits, withdrawals, and rebalances for the Tank contracts 
*/
contract RariFundManager is IRariFundManager, Ownable {
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

    function deposit(address erc20Contract, uint256 amount) external override {}
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