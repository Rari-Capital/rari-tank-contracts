pragma solidity ^0.7.0;

import "./external/compound/ICErc20.sol";
import "./external/compound/IComptroller.sol";
import "./external/compound/IPriceFeed.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RariDataProvider {
    using SafeMath for uint256;

    //@dev The address of Compound's Comptroller
    address constant comptrollerContract = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    //@dev The address of Compound's Price Feed Contract
    address constant priceFeedContract = 0x922018674c12a7F0D394ebEEf9B58F186CdE13c1;

    /**
        @dev Get 
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
    */
    function getMaxUSDBorrowAmount(
        address underlying,
        uint256 amount
    ) external view returns (uint256) {
        IComptroller comptroller = IComptroller(comptrollerContract);
        address cerc20Contract = getCErc20Contract(underlying);
        IPriceFeed priceFeed = IPriceFeed(priceFeedContract);
        
        //(, uint256 liquidity, ) = comptroller.getAccountLiquidity(address(this));

        uint256 price = priceFeed.getUnderlyingPrice(cerc20Contract);

        uint256 usdBalance = amount.mul(price).div(1e18);
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(cerc20Contract);

        return usdBalance.mul(collateralFactorMantissa).div(1e18);
    }

    /**
        @dev Given a USD amount, calculate the maximum borrow amount with that sum
        @param underlying The address of the underlying ERC20 contract
        @param usdAmount The USD value available
    */
    function getUSDToUnderlying (
        address underlying,
        uint256 usdAmount
    ) external view returns (uint256) {
        address cErc20Contract = getCErc20Contract(underlying);
        IPriceFeed priceFeed = IPriceFeed(priceFeedContract);

        //Get the price of the underlying asset
        uint256 underlyingPrice = priceFeed.getUnderlyingPrice(cErc20Contract);
        return usdAmount.mul(10**18).div(underlyingPrice);
    }

    /**
        @dev Use the exchange rate to convert from CErc20 to Erc20 values
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
     */
    function getUnderlyingToCTokens(address underlying, uint256 amount) external returns (uint256) {
        uint256 exchangeRate = ICErc20(getCErc20Contract(underlying)).exchangeRateCurrent();
        uint256 mintAmount = amount.mul(1e18).div(exchangeRate);

        return mintAmount;
    }

    /**
        @dev Use the exchange rate to convert fromn CErc20 to Erc20 Values
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
    */
    function getCTokensToUnderlying(address underlying, uint256 amount) external returns (uint256) {
        uint256 exchangeRate = ICErc20(getCErc20Contract(underlying)).exchangeRateCurrent();
        return exchangeRate.mul(amount).div(1e18);
    }

    /**
        @dev Retrieve the borrowed balance for the contract
        @param underlying The address of the underlying ERC20 contract
     */
    function borrowBalanceCurrent(address underlying) external returns (uint256) {
        return ICErc20(getCErc20Contract(underlying)).borrowBalanceCurrent(msg.sender);
    }

    /**
    @dev Get the underlying price of the asset scaled by 1e18
    @param underlying The address of the underlying ERC20 contract
    */
    function getUnderlyingPrice(address underlying) public view returns (uint256) {
        return IPriceFeed(priceFeedContract).getUnderlyingPrice(getCErc20Contract(underlying));
    }

    /**
        @dev Use the exchange rate to calculate the USD price of x tokens
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
    */
    function getPrice(address underlying, uint256 amount) external view returns (uint256) {
        uint256 price = getUnderlyingPrice(underlying);
        return price.mul(amount).div(1e18);
    }

    /**
        @dev Returns a token's cToken contract address given its ERC20 contract address.
        @param underlying The address of the underlying asset 
    */
    function getCErc20Contract(address underlying) private pure returns (address) {
        //prettier-ignore
        if (underlying == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return 0x35A18000230DA775CAc24873d00Ff85BccdeD550; // UNI => cUNI
        //prettier-ignore
        if (underlying == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC => cUSDC
        //prettier-ignore
        if (underlying == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4; // WBTC => cWBTC
        //prettier-ignore
        if (underlying == 0xE41d2489571d322189246DaFA5ebDe1F4699F498) return 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407; // ZRX => cZRX
        //prettier-ignore
        else revert("CompoundPoolController: Supported cToken address not found for this token address");
    }
}
