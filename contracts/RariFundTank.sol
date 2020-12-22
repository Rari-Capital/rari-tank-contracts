pragma solidity ^0.5.0;

import "./libraries/CompoundPoolController.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
    @title RariFundTank
    @notice Handles interaction with Compound and Rari Pools to earn yield
    @author Jet Jadeja (jet@rari.capital)
*/
contract RariFundTank is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ///@dev The token represented by the tank
    address private supportedToken;

    ///@dev The address of the RariFundController Contract
    address private rariFundController;

    ///@dev Maps user addresses to their cToken balances
    mapping(address => uint256) private cTokenBalances;

    ///@dev Compound's Comptroller Contract
    address private comptroller;

    ///@dev Compound's Pricefeed program
    address private priceFeed;

    ///@dev Ensures that a function can only be called from the RariFundController
    modifier onlyController() {
        require(
            msg.sender == rariFundController,
            "RariFundTank: Function must be called by the Fund Controller"
        );
        _;
    }

    constructor(
        address _supportedToken,
        address _rariFundController,
        address _comptroller,
        address _priceFeed
    ) public {
        supportedToken = _supportedToken;
        rariFundController = _rariFundController;
        comptroller = _comptroller;
        priceFeed = _priceFeed;
    }

    ///@dev An array of addresses whose funds have yet to be converted to cTokens
    address[] private unusedDeposits;

    ///@dev The version number of the data
    uint256 private dataVersionNumber;

    ///@dev Maps addresses to the amount of unused funds they have deposited
    mapping(bytes32 => uint256) private unusedDepositBalances;

    ///@dev The total unused token balance
    uint256 private totalUnusedBalance;

    /**
        @dev Deposit funds into the tank
        @param account The address that supplied the funds
        @param amount The amount of the fund being supplied
    */
    function deposit(address account, uint256 amount) external onlyController() {
        IERC20(supportedToken).safeTransferFrom(account, address(this), amount);

        bytes32 key = keccak256(abi.encode(account, dataVersionNumber));
        if (unusedDepositBalances[key] == 0) unusedDeposits.push(account);
        unusedDepositBalances[key] += amount;
        totalUnusedBalance += amount;
    }

    /**
        @dev Deposit unused funds to Compound, borrow funds and deposit them into Rari's Stable Pool
        @param erc20Contract The address of the asset to be borrowed
    */
    function depositUnusedFunds(address erc20Contract) external onlyController() {
        for (uint256 i = 0; i < unusedDeposits.length; i++) {
            address account = unusedDeposits[i];
            //prettier-ignore
            uint256 deposited = unusedDepositBalances[keccak256(abi.encode(account, dataVersionNumber))];

            // Store cToken Balance using exchange rate data
            cTokenBalances[account] = CompoundPoolController.getUnderlyingToCTokens(
                supportedToken,
                deposited
            );
        }

        CompoundPoolController.deposit(supportedToken, totalUnusedBalance, comptroller);

        //prettier-ignore
        uint256 totalUsdBorrowAmount = CompoundPoolController.getMaxUSDBorrowAmount(
            supportedToken,
            totalUnusedBalance,
            comptroller,
            priceFeed
        );

        //prettier-ignore
        uint256 maxCurrencyBorrowAmount = CompoundPoolController.getAssetBorrowAmount(
            supportedToken,
            totalUsdBorrowAmount,
            comptroller
        );

        // Borrow funds
        CompoundPoolController.borrow(erc20Contract, maxCurrencyBorrowAmount.div(2));

        // Clear data about unused funds
        delete unusedDeposits;
        delete totalUnusedBalance;
        dataVersionNumber++;
    }
}
