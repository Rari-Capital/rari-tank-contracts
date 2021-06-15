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

    /***************
     * Constructor *
     ***************/
    /** @dev Initialize the Tank contract (acts as a constructor) */
    function initialize(address _token, address _comptroller) external {
        require(!initalized, "Tank: Initialization has already occured");
        require(
            IFusePoolDirectory(0x835482FE0532f169024d5E9410199369aAD5C77E).poolExists(
                comptroller
            ),
            "TankFactory: Invalid Comptroller address"
        );

        token = _token;
        comptroller = _comptroller;

        /* 
            Ideally, this would be a constant state variable, 
            but since this is a proxy contract, it would be unsafe
        */
        address borrowing = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
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

    /** @dev Rebalance the Tank. This means rebalancing the Tank's borrow balance  */
    function rebalance(bool useWeth) external onlyFactory {}

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
}
