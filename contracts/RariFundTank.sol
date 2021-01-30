pragma solidity 0.7.3;

/* Interfaces */
import {IRariFundTank} from "./interfaces/IRariFundTank.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/* External */
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
    @title RariFundTank
    @author Jet Jadeja <jet@rari.capital>
    @dev Holds funds, interacts directly with Fuse, and also represents the Rari Tank Token
*/
contract RariFundTank is IRariFundTank, ERC20 {
    /*************
     * Variables *
    *************/

    /***************
     * Constructor *
    ***************/
    constructor() ERC20("", "") {}

    function deposit(uint256 amount) external override {}
    function withdraw(uint256 amount) external override {}

    function rebalance() external override {}
    function exchangeRateCurrent() external override returns (uint256) {}
}