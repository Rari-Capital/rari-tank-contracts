pragma solidity ^0.5.0;

import "../external/compound/CErc20.sol";
import "../external/compound/Comptroller.sol";
import "../external/compound/Pricefeed.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/SafeERC20.sol";

/**
    @title CompoundPoolController
    @author David Lucid (david@rari.capital), Jet Jadeja (jet@rari.capital)
    @dev This library is used to handle interactions with Compound
*/
library CompoundPoolController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
        @dev Deposits collateral into Compound
        @param erc20Contract The address of the underlying asset being supplied
        @param amount The amount of the asset being supplied
        @param comptrollerContract The address of Compound's Comptroller
    */
    function deposit(
        address erc20Contract,
        uint256 amount,
        address comptrollerContract
    ) external {
        require(amount > 0, "CompoundPoolController: Amount must be greater than 0");

        address cErc20Contract = getCErc20Contract(erc20Contract);
        CErc20 cToken = CErc20(cErc20Contract);
        Comptroller comptroller = Comptroller(comptrollerContract);

        // Approve the transfer of the underlying token as collateral
        IERC20(erc20Contract).approve(cErc20Contract, amount);

        // Mint cTokens in return for the underlying assset
        uint256 error = cToken.mint(amount);
        require(error == 0, "CERC20: Mint Error");

        // Enter markets
        address[] memory cTokens = new address[](1);
        cTokens[0] = cErc20Contract;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);

        require(errors[0] == 0, "Comptroller: Failed to enter markets");
    }


    /**
        @dev Borrows a certain amount of an asset from Compound
        @param erc20Contract The address of the underlying asset being borrowed
        @param amount The amount of the underlying asset being supplied
    */
    function borrow(address erc20Contract, uint256 amount) external {
        require(amount > 0, "CompoundPoolController: Amount must be greater than 0");

        //Borrow Tokens
        CErc20(getCErc20Contract(erc20Contract)).borrow(amount);
    }

    /**
        @dev Get the maximum borrow amount in USD
        @param erc20Contract The address of underlying ERC20 Contract
        @param amount The amount 
    */
    function getMaxUSDBorrowAmount(
        address erc20Contract, 
        uint256 amount, 
        address comptrollerContract,
        address priceFeedContract
    ) external returns (uint256) {
        address cErc20Contract = getCErc20Contract(erc20Contract);
        CErc20 cToken = CErc20(cErc20Contract);
        Comptroller comptroller = Comptroller(comptrollerContract);
        PriceFeed priceFeed = PriceFeed(priceFeedContract);
        
        // Get the collateral factor of the asset
        (, uint256 collateralFactorMantissa) = comptroller.markets(cErc20Contract);

        // Calculate the USD Amount
        uint256 underlyingBalanceMantissa = amount
            .mul(cToken.exchangeRateCurrent())
            .div(1e18);

        uint256 usdBalanceMantissa = underlyingBalanceMantissa
            .mul(priceFeed.getUnderlyingPrice(cErc20Contract))
            .div(1e18);

        // Calculate and return the total USD borrow amount
        return usdBalanceMantissa
            .mul(collateralFactorMantissa)
            .div(1e18);
    }

    /**
        @dev Given a USD amount, calculate the maximum borrow amount with that sum
        @param erc20Contract The address of the underlying ERC20 contract
        @param usdAmount The USD value available
    */
    function getAssetBorrowAmount(address erc20Contract, uint256 usdAmount, address priceFeedContract) external view returns (uint256) {
        PriceFeed priceFeed = PriceFeed(priceFeedContract);
        address cErc20Contract = getCErc20Contract(erc20Contract);
        
        //Get the price of the underlying asset
        uint256 underlyingPrice = priceFeed.getUnderlyingPrice(cErc20Contract);

        return usdAmount.mul(1e6).div(underlyingPrice);
    }

    /**
        @dev Use the exchange rate to convert from Erc20 to CErc20
        @param erc20Contract The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
     */
    function getUnderlyingToCTokens(address erc20Contract, uint256 amount) external returns (uint256) {
        return amount.mul(1e18).div(CErc20(erc20Contract).exchangeRateCurrent());
    }


    /**
        @dev Returns a token's cToken contract address given its ERC20 contract address.
        @param erc20Contract The ERC20 contract address of the token
    */
    function getCErc20Contract(address erc20Contract) private pure returns (address) {
        if (erc20Contract == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) return 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E; // BAT => cBAT
        if (erc20Contract == 0xc00e94Cb662C3520282E6f5717214004A7f26888) return 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4; // COMP => cCOMP
        if (erc20Contract == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // DAI => cDAI
        if (erc20Contract == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return 0x35A18000230DA775CAc24873d00Ff85BccdeD550; // UNI => cUNI
        if (erc20Contract == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC => cUSDC
        if (erc20Contract == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT => cUSDT
        if (erc20Contract == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4; // WBTC => cWBTC
        else revert("CompoundFundController: Supported Compound cToken address not found for this token address");
    }
}
