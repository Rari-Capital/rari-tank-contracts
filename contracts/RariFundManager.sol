pragma solidity ^0.7.0;

import "./RariFundController.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
    @title RariFundManager
    @notice Handles deposits and withdrawals into the Tanks
    @author Jet Jadeja (jet@rari.capital)
*/
contract RariFundManager is Ownable {
    using SafeMath for uint256;

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
        addSupportedCurrency("WBTC", 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 8);
        addSupportedCurrency("UNI", 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 18);
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
        address erc20Contract = currencyAddresses[currencyCode];
        //prettier-ignore
        require(erc20Contract != address(0), "RariFundManager: Invalid Currency Code");
        rariFundController.deposit(erc20Contract, msg.sender, amount);
    }

    function withdraw(string calldata currencyCode, uint256 amount) external {
        address erc20Contract = currencyAddresses[currencyCode];

        require(erc20Contract != address(0), "RariFundManager: Invalid Currency Code");
        rariFundController.withdraw(erc20Contract, msg.sender, amount);
    }
}
