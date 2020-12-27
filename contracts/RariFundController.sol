pragma solidity ^0.7.0;

import "./RariFundTank.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
    @title RariFundController
    @notice Handles interactions with the individual tanks
    @author Jet Jadeja (jet@rari.capital)
*/
contract RariFundController is Ownable {
    ///@dev The address of the RariFundManager
    address private rariFundManager;

    ///@dev The address of the rebalancer
    address private fundRebalancer;

    ///@dev An array of the addresses of the RariFundTanks
    address[] private rariFundTanks;

    ///@dev Maps currency to tank address
    mapping(address => address) rariFundTankTokens;

    ///@dev Compound's Comptroller Contract
    address private comptroller;

    ///@dev Compound's Pricefeed program
    address private priceFeed;

    constructor(
        address _rariFundManager, 
        address _fundRebalancer, 
        address _comptroller, 
        address _priceFeed
    ) {
        rariFundManager = _rariFundManager;
        fundRebalancer = _fundRebalancer;
        comptroller = _comptroller;
        priceFeed = _priceFeed;
    }

    modifier onlyRariFundManager() {
        require(
            msg.sender == rariFundManager,
            "RariFundController: Function must be called by the RariFundManager"
        );
        _;
    }

    modifier onlyFundRebalancer() {
        require(
            msg.sender == fundRebalancer,
            "RariFundController: Function must be called by the Fund Rebalanncer"
        );
        _;
    }

    /**
        @dev Deploys a new RariFundTank and store it in the contract
        @param erc20Contract The address of the ERC20 token to be supported by the tank
    */
    function newTank(address erc20Contract) external onlyOwner() {
        RariFundTank tank = new RariFundTank(erc20Contract, comptroller, priceFeed);
        rariFundTanks.push(address(tank));
        rariFundTankTokens[erc20Contract] = address(tank);
    }

    /**
        @dev Given the address of a currency, return the address of its corresponding tank
        @param erc20Contract The address of the ERC20 Token that the tank corresponds to
    */
    function getTank(address erc20Contract) external view returns (address) {
        address tank = rariFundTankTokens[erc20Contract];
        if (tank != address(0)) return tank;
        else revert("RariFundController: Tank not supported");
    }

    /**
        @dev Deposit funds into a specific tank
        @param erc20Contract The address of the ERC20 Token to be deposited
        @param account The address of the depositer
        @param amount The amount that is being deposited
    */
    function deposit(
        address erc20Contract,
        address account,
        uint256 amount
    ) external onlyRariFundManager() {
        RariFundTank tank = RariFundTank(rariFundTankTokens[erc20Contract]);
        tank.deposit(account, amount);
    }
}
