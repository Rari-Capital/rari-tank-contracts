pragma solidity ^0.5.0;

import "./RariFundTank.sol";

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
    @title RariFundController
    @notice Holds the funds handling deposits and withdrawals into Compound and the Rari Stable Pool 
    @author Jet Jadeja (jet@rari.capital) 
*/
contract RariFundController is Ownable, Initializable {
    using SafeERC20 for IERC20;

    ///@dev The address of the RariFundManager contract
    address private rariFundManager;

    ///@dev An array of RariFundTank addresses
    address[] private rariFundTanks;

    ///@dev Maps currencies to their corresponding tank
    mapping(address => address) private rariFundTankTokens;

    function initialize(address _rariFundManager) public initializer {
        rariFundManager = _rariFundManager;
    }

    ///@dev Ensures that a function can only be called from the RariFundController
    modifier onlyFundManager() {
        //prettier-ignore
        require(msg.sender == rariFundManager, "RariFundController: Function must be called by the Fund Manager");
        _;
    }

    event NewTankSet(address token, address tank);

    /**
        @dev Deploy a new tank and add it to the contract
        @param token The address of the token supported by the tank
    */
    function newTank(
        address token,
        address comptroller,
        address priceFeed
    ) external onlyOwner() {
        //prettier-ignore
        RariFundTank tank = new RariFundTank(token, address(this), comptroller, priceFeed);
        rariFundTanks.push(address(tank));
        rariFundTankTokens[token] = address(tank);

        emit NewTankSet(token, address(tank));
    }

    event Deposit(address token, address account, uint256 amount);

    /**
        @dev Deposit tokens into one of the RariFundTanks
        @param token The address of the token
        @param account The address depositing
        @param amount The amount being deposited
    */
    function deposit(
        address token,
        address account,
        uint256 amount
    ) external onlyFundManager() {
        emit Deposit(token, account, amount);

        address tank = rariFundTankTokens[token];
        require(tank != address(0), "RariFundController: Incompatible Token");
        RariFundTank(tank).deposit(account, amount);
    }

    /**
        @dev Given the address of an ERC20 token, get the address of it's corresponding tank
        @param token The address of the token
    */
    function getTank(address token) external view returns (address) {
        return rariFundTankTokens[token];
    }
}
