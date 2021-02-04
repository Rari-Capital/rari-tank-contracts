pragma solidity 0.7.3;

/* Interfaces */
import {IRariFundTank} from "./interfaces/IRariFundTank.sol";
import {IRariDataProvider} from "./interfaces/IRariDataProvider.sol";

import {IComptroller} from "./external/compound/IComptroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* Libraries */
import {FusePoolController} from "./lib/FusePoolController.sol";
import {RariPoolController} from "./lib/RariPoolController.sol";
import {UniswapController} from "./lib/UniswapController.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
    @title RariFundTank
    @author Jet Jadeja <jet@rari.capital>
    @dev Holds funds, interacts directly with Fuse, and also represents the Rari Tank Token
*/
contract RariFundTank is IRariFundTank, ERC20 {
    using SafeMath for uint256;

    /*************
     * Constants *
    *************/
    address private constant BORROWING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string private constant BORROWING_SYMBOL = "USDC";

    /*************
     * Variables *
    *************/
    
    /** @dev The address of the ERC20 token supported by the tank */
    address public token;

    /** @dev The address of the CErc20 Contract representing the tank's underlying token */
    address public cToken;

    /** @dev The address of the RariFundManager */
    address private fundManager;

    /** @dev The address of the RariDataProvider */
    address private dataProvider;

    /** 
        @dev The address of cToken representing the borrowed token 
        This will be removed when the Comptroller underlying => cToken map is implemented
    */
    address private borrowCToken;

    /** @dev The address of the FusePool Comptroller */
    address private comptroller;

    /** @dev A count of undeposited funds */
    uint256 private dormantFunds;

    /** @dev The tank's borrow balance */
    uint256 private borrowBalance;

    /** @dev The tank's stable pool balance */
    uint256 private stablePoolBalance;

    /*************
     * Modifiers *
    **************/
    modifier onlyFundManager() {
        require(msg.sender == address(0), "RariFundTank: Function can only be called by the RariFundManager");
        _;
    }

    /***************
     * Constructor *
    ***************/
    constructor(
        address _fundManager, 
        address _comptroller,
        address _token, 
        address _cToken,
        address _borrowCToken
    ) 
        ERC20(
            string(abi.encodePacked("Rari Tank ", ERC20(_token).name())),
            string(abi.encodePacked("rtt-", ERC20(_token).symbol(), "-USDC"))
        ) 
    {
        fundManager = _fundManager;
        token = _token;
        cToken = _cToken;
        comptroller = _comptroller;
        borrowCToken = _borrowCToken;
    }

    /********************
    * External Functions *
    ********************/
    function deposit(address account, uint256 amount) external override onlyFundManager {
        uint256 mantissa = 18 - ERC20(token).decimals();
        uint256 exchangeRate = exchangeRateCurrent();

        dormantFunds += amount; // Increase the tank's total balance
        _mint(account, amount.mul(exchangeRate).div(10**mantissa)); // Mints RTT
    }
    function withdraw(address account, uint256 amount) external override onlyFundManager {}

    /** @dev Rebalance the pool, depositing dormant funds and handling profits */
    function rebalance() external override onlyFundManager {
        registerProfit();
        depositDormantFunds();
    }

    /*******************
    * Public Functions *
    ********************/

    /** @return The exchange rate between the RTT and the underlying token */
    function exchangeRateCurrent() 
        public 
        override  
        returns (uint256) 
    {
        uint256 mantissa = 18 - ERC20(token).decimals();
        uint256 balance = dormantFunds.add(FusePoolController.balanceOfUnderlying(cToken)).mul(10**mantissa);
        uint256 totalSupply = totalSupply();

        if(balance == 0 || totalSupply == 0) return 50e18; // The initial exchange rate should be 50
        return balance.mul(1e18).div(totalSupply);
    }

    /********************
    * Private Functions *
    *********************/

    /** @dev Deposit dormant funds into a FusePool, borrow a stable asset and put it into the stable pool */
    function depositDormantFunds() private {

        IRariDataProvider rariDataProvider = IRariDataProvider(dataProvider);
        FusePoolController.deposit(token, cToken, dormantFunds);
        
        uint256 balanceOfUnderlying = FusePoolController.balanceOfUnderlying(cToken);
        uint256 borrowAmountUSD = rariDataProvider.maxBorrowAmountUSD(IComptroller(comptroller), cToken, balanceOfUnderlying);
        
        uint256 idealBorrowBalance = rariDataProvider.convertUSDToUnderlying(IComptroller(comptroller).oracle(), borrowCToken, borrowAmountUSD);

        //uint256 currentBorrowBalance = FusePoolController.borrowBalanceCurrent(borrowCToken);

        if(idealBorrowBalance > borrowBalance) borrow(idealBorrowBalance - borrowBalance);
        if(borrowBalance > idealBorrowBalance) repay(borrowBalance - idealBorrowBalance);
    }

    /** @dev Register profits and repay interest */
    function registerProfit() private {
        uint256 currentStablePoolBalance = RariPoolController.balanceOf().div(1e12);
        uint256 currentBorrowBalance = FusePoolController.borrowBalanceCurrent(borrowCToken);
        
        uint256 profit = currentStablePoolBalance > stablePoolBalance ? 
            currentStablePoolBalance.sub(stablePoolBalance) : 
            0;

        uint256 debt = currentBorrowBalance > borrowBalance ? 
            currentBorrowBalance.sub(borrowBalance) : 
            0;

        RariPoolController.withdraw(BORROWING_SYMBOL, profit);

        if(debt > profit) {
            FusePoolController.repay(borrowCToken, profit);
            return;
        }

        FusePoolController.repay(borrowCToken, debt);
        
        uint256 underlyingProfit = swapInterestForUnderlying(profit- debt);
        FusePoolController.deposit(comptroller, cToken, underlyingProfit);
    }

    /** @dev Borrow a stable asset from Fuse and deposit it into Rari */
    function borrow(uint256 amount) private {
        FusePoolController.borrow(borrowCToken, amount);
        borrowBalance += amount;

        RariPoolController.deposit(BORROWING_SYMBOL, BORROWING, amount);
        stablePoolBalance += amount;
    }

    /** @dev Withdraw a stable asset from Rari and repay  */
    function repay(uint256 amount) private {
        RariPoolController.withdraw(BORROWING_SYMBOL, amount);
        stablePoolBalance -= amount;

        FusePoolController.repay(borrowCToken, amount);
        borrowBalance -= amount;
    }

    /** 
        @dev Facilitate a swap from the borrowed token to the underlying token 
        @return The amount of tokens returned by Uniswap
    */
    function swapInterestForUnderlying(uint256 amount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = BORROWING;
        path[1] = token;
        return UniswapController.swapTokens(path, amount);
    }
}