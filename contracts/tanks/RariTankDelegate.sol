pragma solidity 0.7.3;

/* Interfaces */
import {IRariTank} from "../interfaces/IRariTank.sol";
import {IRariDataProvider} from "../interfaces/IRariDataProvider.sol";
import {IComptroller} from "../external/compound/IComptroller.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RariTankStorage} from "./RariTankStorage.sol";

/* Libraries */
import {FusePoolController} from "../lib/FusePoolController.sol";
import {RariPoolController} from "../lib/RariPoolController.sol";
import {UniswapController} from "../lib/UniswapController.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/* External */
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
    @title Rari Tank Delegate
    @author Jet Jadeja <jet@rari.capital>
    @dev Implementation for the USDC Stable Pool tank
*/
contract RariTankDelegate is IRariTank, RariTankStorage, ERC20Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*************
     * Constants *
    *************/
    address private constant BORROWING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string private constant BORROWING_SYMBOL = "USDC";

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
    function initialize(
        address _token,
        address _comptroller,
        address _fundManager,
        address _dataProvider
    )
        external
    {
        require(!initialized, "Contract already initialized");
        initialized = true;

        __ERC20_init(
            string(abi.encodePacked("Rari Tank ", ERC20Upgradeable(_token).name())),
            string(abi.encodePacked("rtt-", ERC20Upgradeable(_token).symbol(), "-USDC"))
        );

        token = _token;
        comptroller = _comptroller;
        fundManager = _fundManager;
        dataProvider = _dataProvider;


        cToken = address(IComptroller(_comptroller).getCTokensByUnderlying(token));
        require(cToken != address(0), "Unsupported asset");
    }

    /********************
    * External Functions *
    ********************/
    /** @dev Deposit into the Tank */
    function deposit(uint256 amount) external override onlyFundManager {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        uint256 exchangeRate = exchangeRateCurrent();

        dormant += amount; // Increase the tank's total balance
        _mint(msg.sender, amount.mul(exchangeRate).div(10**mantissa)); // Mints RTT
    }

    /** @dev Withdraw from the Tank */
    function withdraw(uint256 amount) external override onlyFundManager {}

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
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        uint256 balance = dormant.add(FusePoolController.balanceOfUnderlying(cToken)).mul(10**mantissa);
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
        FusePoolController.deposit(token, cToken, dormant);
        
        uint256 balanceOfUnderlying = FusePoolController.balanceOfUnderlying(cToken);
        uint256 borrowAmountUSD = rariDataProvider.maxBorrowAmountUSD(IComptroller(comptroller), cToken, balanceOfUnderlying);
        
        uint256 idealBorrowBalance = rariDataProvider.convertUSDToUnderlying(IComptroller(comptroller), borrowCToken, borrowAmountUSD);

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