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
    using SafeMath for uint256;

    /*************
     * Constants *
    *************/
    address private constant BORROWING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string private constant BORROWING_SYMBOL = "USDC";

    /*************
     * Variables *
    *************/

    /** @dev The address of the RariFundManager */
    address private fundManager;

    /** @dev The address of the ERC20 token supported by the tank */
    address public token;

    /** @dev The address of the CErc20 Contract representing the tank's underlying token */
    address private cToken;

    /** 
        @dev The address of cToken representing the borrowed token 
        This will be removed when the Comptroller underlying => cToken map is implemented
    */
    address private borrowCToken;

    /** @dev The address of the FusePool Comptroller */
    address private comptroller;

    /** @dev A count of undeposited funds */
    uint256 private dormantFunds;

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
        address _comptroller
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

        _mint(account, amount.mul(exchangeRate).div(10**mantissa));
        dormantFunds += amount;
    }
    function withdraw(address account, uint256 amount) external override onlyFundManager {}

    /** @dev Rebalance the pool, depositing dormant funds and handling profits */
    function rebalance() external override onlyFundManager {}

    /*******************
    * Public Functions *
    ********************/

    /** @return The exchange rate between the RTT and the underlying token */
    function exchangeRateCurrent() 
        public 
        view 
        override  
        returns (uint256) 
    {
        uint256 mantissa = 18 - ERC20(token).decimals();
        uint256 balance = dormantFunds.mul(10**mantissa);
        uint256 totalSupply = totalSupply();

        if(balance == 0 || totalSupply == 0) return 50e18; // The initial exchange rate should be 50
        return balance.mul(1e18).div(totalSupply);
    }
}