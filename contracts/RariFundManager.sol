pragma solidity ^0.5.0;

import "./RariFundController.sol";

/**
    @title RariFundManager
    @notice Handles deposits and withdrawals into the pool
    @author Jet Jadeja (jet@rari.capital)
*/
contract RariFundManager {
    ///@dev The address of the RariFundController Contract
    address private rariFundControllerContract;

    ///@dev An array of supported currencies
    string[] private supportedCurrencies;

    ///@dev Maps supported currencies to their indexes
    mapping(string => uint256) private currencyIndexes;

    ///@dev Maps supported currency codes to their correpsonding ERC20 contract addresses
    mapping(string => address) private currencyAddresses;

    ///@dev Maps supported currency codes to their decimal precisions
    mapping(string => uint256) private currencyDecimals;

    constructor() public {
        addSupportedCurrency("BAT", 0x0D8775F648430679A709E98d2b0Cb6250d2887EF, 18);
        addSupportedCurrency("COMP", 0xc00e94Cb662C3520282E6f5717214004A7f26888, 18);
        addSupportedCurrency("WBTC", 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 8);
        addSupportedCurrency("UNI", 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 18);
        addSupportedCurrency("USDC", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 6);
        addSupportedCurrency("USDT", 0xdAC17F958D2ee523a2206206994597C13D831ec7, 6);
        addSupportedCurrency("ZRX", 0xE41d2489571d322189246DaFA5ebDe1F4699F498, 18);
    }

    ///@dev Add a supported ERC20 token to the contract
    function addSupportedCurrency(
        string memory _currencyCode,
        address _currencyAddress,
        uint256 _decimals
    ) internal {
        currencyIndexes[_currencyCode] = supportedCurrencies.length;
        supportedCurrencies.push(_currencyCode);

        currencyAddresses[_currencyCode] = _currencyAddress;
        currencyDecimals[_currencyCode] = _decimals;
    }
}
