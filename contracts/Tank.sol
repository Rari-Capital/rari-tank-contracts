pragma solidity 0.7.3;

/* Storage */
import {TankStorage} from "./helpers/tanks/TankStorage.sol";
import {ITank} from "./interfaces/ITank.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";

/* Interfaces */
import {IComptroller} from "./external/compound/IComptroller.sol";
import {ICErc20} from "./external/compound/ICErc20.sol";
import {IPriceFeed} from "./external/compound/IPriceFeed.sol";
import {IFusePoolDirectory} from "./external/fuse/IFusePoolDirectory.sol";

//prettier-ignore
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Libraries */
import {MarketController} from "./libraries/MarketController.sol";
import {YieldSourceController} from "./libraries/YieldSourceController.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

/** 
    @title Tank
    @author Jet Jadeja <jet@rari.capital>
    @dev The default Tank contract, supplies an asset to Fuse, borrows another asset, and earns interest on it.
*/
contract Tank is TankStorage, ERC20Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*************
     * Variables *
     *************/

    /** @dev The address of the ERC20 token that users deposit/earn yield on in the Tank */
    address public token;

    /** @dev The address of the Fuse fToken that represents the Tank's underlying balance */
    address public cToken;

    /** @dev The token that the Tank borrows and deposits into a yield source */
    address public borrowing;

    /** @dev Address of the FusePool Comptroller token */
    address internal comptroller;

    /** @dev A value representing the ideal (percentage) used borrow limit scaled by 1e18 */
    uint256 internal idealUsedBorrowLimit;

    /** @dev Borrow balance, set whenever funds are borrowed or repaid */
    uint256 internal lastBorrowBalance;

    /** @dev Yield source Balance, set whenever funds are deposited or withdrawn */
    uint256 internal lastYieldSourceBalance;

    /***************
     * Constructor *
     ***************/
    /** @dev Initialize the Tank contract (acts as a constructor) */
    function initialize(bytes memory data) external initializer {
        (address _token, address _comptroller) = abi.decode(data, (address, address));

        require(
            IFusePoolDirectory(0x835482FE0532f169024d5E9410199369aAD5C77E).poolExists(
                _comptroller
            ),
            "TankFactory: Invalid Comptroller address"
        );

        token = _token;
        comptroller = _comptroller;

        /* 
            Ideally, this would be a constant state variable, 
            but since this is a proxy contract it would be unsafe
        */
        borrowing = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        idealUsedBorrowLimit = 55e16; // 55%

        string memory borrowSymbol = ERC20Upgradeable(borrowing).symbol();
        cToken = address(IComptroller(_comptroller).cTokensByUnderlying(_token));

        __ERC20_init(
            string(abi.encodePacked("Tank ", ERC20Upgradeable(_token).name())),
            string(
                abi.encodePacked("rtt-", ERC20Upgradeable(_token).symbol(), borrowSymbol)
            )
        );

        require(cToken != address(0), "Unsupported asset");
        require(
            address(IComptroller(_comptroller).cTokensByUnderlying(borrowing)) !=
                address(0),
            "Unsupported borrow asset"
        );
    }

    /*************
     * Mofifiers *
     *************/

    modifier onlyFactory() {
        require(msg.sender == factory, "Tank: Can only be called by the factory");
        _;
    }

    /********************
     * External Functions *
     *********************/
    /** @dev Deposit into the Tank */
    function deposit(uint256 amount) external {
        uint256 decimals = ERC20Upgradeable(token).decimals();
        uint256 priceMantissa = 18 - decimals;
        uint256 price = MarketController.getPriceEth(comptroller, token);

        uint256 deposited = price.mul(amount).div(1e18); //The deposited amount in ETH
        console.log(
            price.div(10**priceMantissa).mul(amount).div(
                10**ERC20Upgradeable(token).decimals()
            )
        );

        require(deposited >= 1e18, "Tank: Amount must be worth at least one Ether");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        MarketController.supply(cToken, amount); // Deposit into Fuse

        uint256 exchangeRate = exchangeRateCurrent();
        _mint(msg.sender, amount.mul(exchangeRate).div(10**decimals));
    }

    /** @dev Deposit devs into the Tanks */
    function withdraw(uint256 amount) external {
        uint256 balance = balanceOfUnderlying(msg.sender);
        require(amount <= balance, "Tank: Amount must be less than balance");

        uint256 exchangeRate = exchangeRateCurrent();
        uint256 decimals = ERC20Upgradeable(token).decimals();

        _burn(msg.sender, amount.mul(10**(36 - decimals)).div(exchangeRate));
        //_withdraw(amount); // Withdraw funds from money market
    }

    /** 
        @dev Rebalance the Tank
        @param useWeth Use Weth when trading between ETH and     
    */
    function rebalance(bool useWeth) external onlyFactory {
        (uint256 profit, bool profitSufficient) = _getProfits(5e15); //0.5 percent
        (uint256 divergence, bool idealGreater, bool divergenceSufficient) =
            _getBorrowBalanceDivergence(15e16); //15%

        require(divergenceSufficient || profitSufficient, "Tank: Cannot be rebalanced");
        bool registerProfits = profit > (lastYieldSourceBalance * 5e15) / 1e18; //0.5%

        if (divergenceSufficient) {
            if (idealGreater) _borrow(divergence, registerProfits ? profit : 0);
            else _repay(divergence, registerProfits ? profit : 0);
        }
    }

    /********************
     * Public Functions *
     ********************/
    /** @dev Get the tank Token Exchange rate */
    function exchangeRateCurrent() public returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        uint256 balance = MarketController.balanceOfUnderlying(cToken) * (10**mantissa);

        if (balance == 0 || totalSupply == 0) return 1e18;
        return balance.mul(1e18).div(balance);
    }

    /** @dev Get a user's balance of underlying tokens */
    function balanceOfUnderlying(address account) public returns (uint256) {
        uint256 balance = balanceOf(account);
        uint256 mantissa = 36 - ERC20Upgradeable(token).decimals();
        uint256 exchangeRate = exchangeRateCurrent();

        return balance.mul(exchangeRate).div(10**mantissa);
    }

    /********************
     * Internal Functions *
     *********************/

    function _registerProfit() internal {}

    /** 
        @dev Get the Tank's profits in the yield source and evaluate whether it is greater than a certain threshold
        @param threshold The threshold for profits 
    */
    function _getProfits(uint256 threshold)
        internal
        returns (uint256 profit, bool sufficient)
    {
        profit = YieldSourceController.balanceOf().sub(lastYieldSourceBalance);
        uint256 thresholdValue = lastYieldSourceBalance.mul(threshold).div(1e18);
        sufficient = profit > thresholdValue;
    }

    /** 
        @dev Get the borrow balance divergence 
        @return divergence the divergence
        @return idealGreater a boolean indicating whether the ideal balance is greater than the current one 
    */
    function _getBorrowBalanceDivergence(uint256 threshold)
        internal
        returns (
            uint256 divergence,
            bool idealGreater,
            bool divergenceSufficient
        )
    {
        uint256 idealBorrowAmount = _getIdealBorrowAmount();

        idealGreater = idealBorrowAmount > lastBorrowBalance;
        divergence = idealGreater ? idealBorrowAmount - lastBorrowBalance : !idealGreater
            ? lastBorrowBalance - idealBorrowAmount
            : 0;

        uint256 borrowThreshold = lastBorrowBalance.mul(threshold).div(1e18);
        divergenceSufficient = divergence > borrowThreshold;
    }

    /** @dev Borrow a stable asset from Fuse and deposit it into Rari */
    function _borrow(uint256 borrowAmount, uint256 depositAmount) internal {
        MarketController.borrow(comptroller, borrowing, borrowAmount);
        lastBorrowBalance += borrowAmount;

        YieldSourceController.deposit(borrowing, borrowAmount - depositAmount);
        lastYieldSourceBalance += borrowAmount - depositAmount;
    }

    /** @dev Withdraw a stable asset from Rari and repay */
    function _repay(uint256 withdrawalAmount, uint256 repayAmount) internal {
        YieldSourceController.withdraw(withdrawalAmount);
        lastYieldSourceBalance -= withdrawalAmount;

        MarketController.repay(comptroller, borrowing, withdrawalAmount - repayAmount);
        lastBorrowBalance -= (withdrawalAmount - repayAmount);
    }

    /** @return the ideal borrow amount */
    function _getIdealBorrowAmount() internal returns (uint256) {
        uint256 usdBorrowAmount =
            MarketController.maxBorrowAmountUSD(cToken, comptroller, token);

        return MarketController.getTokensFromUsd(comptroller, token, usdBorrowAmount);
    }
}
