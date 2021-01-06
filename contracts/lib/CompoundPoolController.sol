pragma solidity ^0.7.0;

import "hardhat/console.sol";

import "../external/compound/ICErc20.sol";
import "../external/compound/IComptroller.sol";
import "../external/compound/IPriceFeed.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
    @title CompoundPoolController
    @author David Lucid (david@rari.capital), Jet Jadeja (jet@rari.capital)
    @dev This library is used to handle interactions with Compound
*/
library CompoundPoolController {
    using SafeMath for uint256;

    /**
        @dev Deposits collateral into Compound
        @param underlying The address of the underlying asset
        @param amount The amount of the asset being supplied
        @param comptrollerContract The address of Compound's Comptroller
    */
    function deposit(
        address underlying,
        uint256 amount,
        address comptrollerContract
    ) internal {
        require(amount > 0, "CompoundPoolController: Amount must be greater than 0");

        address cErc20Contract = getCErc20Contract(underlying);
        ICErc20 cToken = ICErc20(cErc20Contract);
        IComptroller comptroller = IComptroller(comptrollerContract);

        // Approve the transfer of the ERC20 Contract
        IERC20(underlying).approve(cErc20Contract, amount);

        // Mint cTokens in return for the underlying asset
        uint256 error = cToken.mint(amount);
        console.log(cToken.balanceOfUnderlying(address(this)));
        require(error == 0, "CERC20: Mint Error");

        // Enter markets
        address[] memory cTokens = new address[](1);
        cTokens[0] = cErc20Contract;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);

        require(errors[0] == 0, "Comptroller: Failed to enter markets");
    }

    /**
        @dev Given the address of an ERC20 token, borrow a certain amount from Compound
        @param underlying The address of the underlying asset
        @param amount The amount to be borrowed
    */
    function borrow(address underlying, uint256 amount) internal {
        require(amount > 0, "CompoundPoolController: Amount must be greater than 0");
        
        //Borrow Tokens
        uint256 error = ICErc20(getCErc20Contract(underlying)).borrow(amount);
        require(error == 0, "CompoundPoolController: Compound Borrow Error");
        console.log(IERC20(underlying).balanceOf(address(this)));
    }

    function repayBorrow(address underlying, uint256 amount) internal {
        uint256 error = ICErc20(getCErc20Contract(underlying)).repayBorrow(amount);
        require(error == 0, "CompoundPoolController: Compound Repay Error");
    }

    /**
        @dev Get 
        @param comptrollerContract The address of Compound's Comptrolle
    */
    function getMaxUSDBorrowAmount(
        address comptrollerContract
    ) internal view returns (uint256) {
        IComptroller comptroller = IComptroller(comptrollerContract);

        (, uint256 liquidity, ) = comptroller.getAccountLiquidity(address(this));
        return liquidity;
    }
    /**
        @dev Given a USD amount, calculate the maximum borrow amount with that sum
        @param underlying The address of the underlying ERC20 contract
        @param usdAmount The USD value available
        @param priceFeedContract The address of Compound's PriceFeed
    */
    function calculateMaxBorrowAmount(
        address underlying,
        uint256 usdAmount,
        address priceFeedContract
    ) internal view returns (uint256) {
        address cErc20Contract = getCErc20Contract(underlying);
        IPriceFeed priceFeed = IPriceFeed(priceFeedContract);

        //Get the price of the underlying asset
        uint256 underlyingPrice = priceFeed.getUnderlyingPrice(cErc20Contract);
        return usdAmount.mul(1e18).div(underlyingPrice);
    }
 
    /**
        @dev Use the exchange rate to convert from Erc20 to CErc20
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
     */
    function getUnderlyingToCTokens(address underlying, uint256 amount) internal returns (uint256) {
        uint256 exchangeRate = ICErc20(getCErc20Contract(underlying)).exchangeRateCurrent();
        uint256 mantissa = 18 + (getERC20Decimals(underlying) - 8);
        uint256 oneCTokenInUnderlying = exchangeRate.mul(10**getERC20Decimals(underlying)).div(10 ** mantissa);

        return amount.mul(10**getERC20Decimals(underlying)).div(oneCTokenInUnderlying);
    }

    /**
        @dev Retrieve the borrowed balance for the contract
        @param underlying The address of the underlying ERC20 contract
     */
    function borrowBalanceCurrent(address underlying) internal returns (uint256) {
        return ICErc20(getCErc20Contract(underlying)).borrowBalanceCurrent(address(this));
    }

    /**
        @dev Use the exchange rate to calculate the USD price of x tokens
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
        @param priceFeedContract The address of Compound's PriceFeed
    */
    function getPrice(address underlying, uint256 amount, address priceFeedContract) internal view returns (uint256) {
        uint256 price = IPriceFeed(priceFeedContract).getUnderlyingPrice(getCErc20Contract(underlying));
        return price.mul(amount).div(1e18);
    }



    /**
        @dev Returns a token's cToken contract address given its ERC20 contract address.
        @param underlying The address of the underlying asset 
    */
    function getCErc20Contract(address underlying) private pure returns (address) {
        if (underlying == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) return 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E; // BAT => cBAT
        if (underlying == 0xc00e94Cb662C3520282E6f5717214004A7f26888) return 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4; // COMP => cCOMP
        if (underlying == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // DAI => cDAI
        if (underlying == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return 0x35A18000230DA775CAc24873d00Ff85BccdeD550; // UNI => cUNI
        if (underlying == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC => cUSDC
        if (underlying == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT => cUSDT
        if (underlying == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4; // WBTC => cWBTC
        else revert("CompoundFundController: Supported cToken address not found for this token address");
    }

    function getERC20Decimals(address underlying) private pure returns (uint256) {
        if (underlying == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) return 18; // BAT
        if (underlying == 0xc00e94Cb662C3520282E6f5717214004A7f26888) return 18; // COMP
        if (underlying == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 18; // DAI
        if (underlying == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return 18; // UNI
        if (underlying == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 6; // USDC
        if (underlying == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 6; // USDT
        if (underlying == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 8; // WBTC
        else revert("CompoundFundController: Unsupported Currency");
    }
}
