pragma solidity ^0.5.0;

import "../external/compound/CErc20.sol";
import "../external/compound/Comptroller.sol";
import "../external/compound/Pricefeed.sol";

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/SafeERC20.sol";

/**
    @title CompoundPoolController
    @author David Lucid <david@rari.capital>, Jet Jadeja (jet@rari.capital)
    @dev This library is used to handle interactions with Compound
*/
library CompoundPoolController {
    using SafeERC20 for IERC20;

    /**
        @dev Returns a token's cToken contract address given its ERC20 contract address.
        @param _erc20Contract The ERC20 contract address of the token
    */
    function getCErc20Contract(address _erc20Contract) private pure returns (address) {
        if (_erc20Contract == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) return 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E; // BAT => cBAT
        if (_erc20Contract == 0xc00e94Cb662C3520282E6f5717214004A7f26888) return 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4; // COMP => cCOMP
        if (_erc20Contract == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // DAI => cDAI
        if (_erc20Contract == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return 0x35A18000230DA775CAc24873d00Ff85BccdeD550; // UNI => cUNI
        if (_erc20Contract == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC => cUSDC
        if (_erc20Contract == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT => cUSDT
        if (_erc20Contract == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4; // WBTC => cWBTC
        else revert("CompoundFundController: Supported Compound cToken address not found for this token address");
    }

    /**
        @dev Deposits collateral into Compound
        @param _underlying The address of the underlying asset being supplied
        @param _amount The amount of the asset being supplied
    */
    function deposit(
        address _underlying,
        uint256 _amount,
        address _comptroller
    ) internal {
        require(_amount > 0, "CompoundPoolController: Amount must be greater than 0");

        address cErc20Contract = getCErc20Contract(_underlying);
        IERC20 underlying = IERC20(_underlying);
        CErc20 cToken = CErc20(cErc20Contract);
        Comptroller comptroller = Comptroller(_comptroller);

        // Approve the transfer of the underlying token as collateral
        underlying.approve(cErc20Contract, _amount);

        // Mint cTokens in return for the underlying assset
        uint256 error = cToken.mint(_amount);
        require(error == 0, "CERC20: Mint Error");

        // Enter markets
        address[] memory cTokens = new address[](1);
        cTokens[0] = cErc20Contract;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);

        require(errors[0] == 0, "Comptroller: Failed to enter markets");
    }

    /**
        @dev Borrows a certain amount of an asset from Compound
        @param _underlying The address of the underlying asset being borrowed
        @param _amount The amount of the underlying asset being supplied
    */
    function borrow(
        address _underlying,
        uint256 _amount
    ) internal {
        require(_amount > 0, "CompoundPoolController: Amount must be greater than 0");

        address cErc20Contract = getCErc20Contract(_underlying);
        CErc20 cToken = CErc20(cErc20Contract);

        cToken.borrow(_amount);
    }
}
