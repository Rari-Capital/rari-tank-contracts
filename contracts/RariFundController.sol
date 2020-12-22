pragma solidity ^0.5.0;

import "./RariFundTank.sol";
import "./libraries/CompoundPoolController.sol";

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/SafeERC20.sol";

/**
    @title RariFundController
    @notice Holds the funds handling deposits and withdrawals into Compound and the Rari Stable Pool 
    @author Jet Jadeja (jet@rari.capital) 
*/
contract RariFundController is Ownable {
    using SafeERC20 for IERC20;

    ///@dev The address of the RariFundManager contract
    address private rariFundManager;

    ///@dev An array of RariFundTank addresses
    address[] private rariFundTanks;

    ///@dev Maps currencies to their corresponding tank
    mapping(address => address) private rariFundTankTokens;

    constructor(address _rariFundManager) public Ownable() {
        rariFundManager = _rariFundManager;
    }

    ///@dev Ensures that a function can only be called from the RariFundController
    modifier onlyFundManager() {
        //prettier-ignore
        require(msg.sender == rariFundManager, "RariFundController: Function must be called by the Fund Manager");
        _;
    }

    /**
        @dev Add a new tank to the contract
        @param token The address of the token supported by the tank
        @param tank The address of the new tank
    */
    function newTank(address token, address tank) external onlyOwner() {
        rariFundTanks.push(tank);
        rariFundTankTokens[token] = tank;
    }

    /**
        @dev Deposit tokens into one of the RariFundTanks
    */
    function deposit(
        address token,
        address account,
        uint256 amount
    ) external onlyFundManager() {
        address tank = rariFundTankTokens[token];

        require(tank != address(0), "RariFundController: Incompatible Token");
        IERC20(token).safeTransferFrom(account, tank, amount);
        RariFundTank(tank).deposit(account, amount);
    }
}
