pragma solidity ^0.5.0;

import "./FundManager.sol";
import "./external/compound/CErc20.sol";
import "./external/compound/Comptroller.sol";
import "./external/compound/PriceFeed.sol";

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract FundController {
    using SafeMath for uint256;

    ///@dev The Fund Manager Smart  Contract
    address private fundManager;

    ///@dev Maps from address to the address of the CToken they
    mapping(address => address) private cTokenUsed;

    ///@dev Maps the amount of each cToken this address holds
    mapping(address => uint256) private cTokenBalances;

    ///@dev Maps user address to the address of their underlying deposited token
    mapping(address => address) private usedUnderlying;

    ///@dev Ensure that the modified function can only be called by the fundManager
    modifier onlyManager() {
        require(
            address(msg.sender) == fundManager,
            "RariFundController: Must be called by the FundManager"
        );
        _;
    }

    function deposit(address tokenContract, address cTokenContract)
        external
        onlyManager()
    {}

    /**
        @dev Internal function to deposit collateral into Compound
        @param _underlyingToken The token that is used as collateral
        @param _amount The amount of _underlyingToken to be supplied
        @param _cToken The address of the Compound Token
        @param _comptroller The address of the comptroller
    */
    function _depositToCompound(
        address _underlyingToken,
        uint256 _amount,
        address _cToken,
        address _comptroller
    ) internal {
        // Ensure that the user doesn't deposit more than 1 currency
        require(
            usedUnderlying[msg.sender] == address(0) ||
                usedUnderlying[msg.sender] == _underlyingToken,
            "RariFundController: Token Type must match deposits"
        );

        usedUnderlying[msg.sender] = _underlyingToken;

        IERC20 underlyingToken = IERC20(_underlyingToken);
        CErc20 cToken = CErc20(_cToken);
        Comptroller comptroller = Comptroller(_comptroller);

        // Approve the transfer of the underlying token to compound as collateral
        underlyingToken.approve(_cToken, _amount);

        // Mint cToken in return for the underlying asset
        uint256 error = cToken.mint(_amount);
        require(error == 0, "cERC20 Mint Error");

        // Enter the market in order to be able to borrow other assets
        address[] memory cTokens = new address[](1);
        cTokens[0] = _cToken;

        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller: Failed to enter markets");
        }
    }

    function _borrowFromCompound(address _comptroller) internal {
        Comptroller comptroller = Comptroller(_comptroller);

        (uint256 error, uint256 liquidity, uint256 shortfall) =
            comptroller.getAccountLiquidity(address(this));

        if (error != 0) {
            revert("Comptroller: Failed to get account liquidity");
        }

        require(shortfall == 0, "Comptroller: account underwater");
        require(liquidity > 0, "Comptroller: account has excess collateral");
    }

    /**
        @dev Private function used to get total borrowAmount for a specific user
        @param _userAddress The address of the user
        @param _comptroller The address of the comptroller
        @param _priceFeed The address of the compound pricefeed
    */
    function getUSDBorrowAmount(
        address _userAddress,
        address _comptroller,
        address _priceFeed
    ) private returns (uint256) {
        // Initialize needed variables
        address cErc20Contract = cTokenUsed[_userAddress];
        CErc20 cToken = CErc20(cErc20Contract);
        uint256 cTokenBalance = cTokenBalances[_userAddress];
        PriceFeed priceFeed = PriceFeed(_priceFeed);
        Comptroller comptroller = Comptroller(_comptroller);

        (, uint256 collateralFactorMantissa) = comptroller.markets(cErc20Contract);

        // Convert CToken Balance to underlying
        uint256 underlyingBalanceMantissa =
            cTokenBalance.mul(cToken.exchangeRateCurrent()).div(1e18);

        // Calculate the user's balance in USD
        uint256 usdBalanceMantissa =
            underlyingBalanceMantissa
                .mul(priceFeed.getUnderlyingPrice(cErc20Contract))
                .div(1e18);

        // Calculate and return the USD Balance Amount
        return usdBalanceMantissa.mul(collateralFactorMantissa).div(1e18);
    }
}
