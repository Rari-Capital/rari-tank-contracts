pragma solidity ^0.7.0;

import {RariFundTank} from "./RariFundTank.sol";
import "hardhat/console.sol";
import "./interfaces/IRariTankToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
    @title RariFundController
    @notice Handles interactions with the individual tanks
    @author Jet Jadeja (jet@rari.capital)
*/
contract RariFundController is Ownable {
    using SafeERC20 for IERC20;

    ///@dev The address of the RariFundManager
    address private rariFundManager;

    ///@dev
    address private rariDataProvider;

    ///@dev The address of the rebalancer
    address private fundRebalancer;

    ///@dev An array of the addresses of the RariFundTanks
    address[] private rariFundTanks;

    ///@dev Maps currency to tank address
    mapping(address => address) rariFundTankTokens;

    ///@dev The address of the Rari Stable Pool Fund Manager
    address private rariStablePool;

    constructor(
        address _rariFundManager,
        address _fundRebalancer,
        address _rariDataProvider
    ) {
        rariFundManager = _rariFundManager;
        fundRebalancer = _fundRebalancer;
        rariDataProvider = _rariDataProvider;
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
    function newTank(
        address erc20Contract,
        uint256 decimals,
        address erc20BorrowContract,
        address tankToken
    ) external onlyOwner() returns (address) {
        //prettier-ignore
        RariFundTank tank = new RariFundTank(
            erc20Contract,
            decimals,
            erc20BorrowContract,
            rariDataProvider,
            tankToken
        );
        rariFundTanks.push(address(tank));
        rariFundTankTokens[erc20Contract] = address(tank);

        return address(tank);
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
        address tankContract = rariFundTankTokens[erc20Contract];

        IERC20(erc20Contract).safeTransferFrom(account, tankContract, amount);
        RariFundTank(tankContract).deposit(account, amount);
    }

    function withdraw(
        address erc20Contract,
        address account,
        uint256 amount
    ) external onlyRariFundManager() {
        address tankContract = rariFundTankTokens[erc20Contract];
        (address token, uint256 burnAmount) =
            RariFundTank(tankContract).withdraw(account, amount);
        IRariTankToken(token).burnFrom(account, burnAmount);
    }

    /**
        @dev Deposit the tanks' unused funds into Compound
    */
    function rebalance(address erc20Contract) external onlyFundRebalancer() {
        RariFundTank tank = RariFundTank(rariFundTankTokens[erc20Contract]);
        tank.rebalance();
    }

    /**
        @dev Get the total amount of tokens locked in the contract
    */
    function getDormantFunds(address erc20Contract) external view returns (uint256) {
        return IERC20(erc20Contract).balanceOf(rariFundTankTokens[erc20Contract]);
    }
}
