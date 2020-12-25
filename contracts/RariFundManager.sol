pragma solidity ^0.7.0;

import "./RariFundController.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
    @title RariFundManager
    @notice Handles deposits and withdrawals into the Tanks
    @author Jet Jadeja (jet@rari.capital)
*/
contract RariFundManager is Ownable {
    ///@dev Address of the RariFundController
    address private rariFundControllerContract;

    ///@dev The RariFundController contract
    RariFundController private rariFundController;

    ///@dev An array of supported currencies
    string[] private supportedCurrencies;

    ///@dev Maps supported currencies to their indexes
    mapping(string => uint256) private currencyIndexes;

    ///@dev Maps supported currency codes to their correpsonding ERC20 contract addresses
    mapping(string => address) private currencyAddresses;

    ///@dev Maps supported currency codes to their decimal precisions
    mapping(string => uint256) private currencyDecimals;

    constructor() {
        addSupportedCurrency("BAT", 0x0D8775F648430679A709E98d2b0Cb6250d2887EF, 18);
        addSupportedCurrency("COMP", 0xc00e94Cb662C3520282E6f5717214004A7f26888, 18);
        addSupportedCurrency("DAI", 0x6B175474E89094C44Da98b954EedeAC495271d0F, 6);
        addSupportedCurrency("WBTC", 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 8);
        addSupportedCurrency("UNI", 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 18);
        addSupportedCurrency("USDC", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 6);
        addSupportedCurrency("USDT", 0xdAC17F958D2ee523a2206206994597C13D831ec7, 6);
        addSupportedCurrency("ZRX", 0xE41d2489571d322189246DaFA5ebDe1F4699F498, 18);
    }

    /**
        @dev Add a supported ERC20 token to the contract
        @param currencyCode The currency code of the token
        @param currencyAddress The ERC20 contract address of the token
        @param decimals The decimal presion of the token
    */
    function addSupportedCurrency(
        string memory currencyCode,
        address currencyAddress,
        uint256 decimals
    ) private {
        currencyIndexes[currencyCode] = supportedCurrencies.length;
        supportedCurrencies.push(currencyCode);
        currencyAddresses[currencyCode] = currencyAddress;
        currencyDecimals[currencyCode] = decimals;
    }

    /**
        @dev Set a new RariFundController
        @param _rariFundControllerContract The address of the new RariFundController
    */
    function setRariFundController(address _rariFundControllerContract)
        external
        onlyOwner
    {
        rariFundControllerContract = _rariFundControllerContract;
        rariFundController = RariFundController(_rariFundControllerContract);
    }

    function deposit(string calldata currencyCode, uint256 amount) external {
        address erc20TokenContract = currencyAddresses[currencyCode];
        //prettier-ignore
        require(erc20TokenContract != address(0), "RariFundManager: Invalid Currency Code");
        rariFundController.deposit(msg.sender, amount);
    }
}
