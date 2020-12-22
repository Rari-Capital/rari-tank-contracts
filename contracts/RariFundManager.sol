pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/SafeERC20.sol";

import "./RariFundController.sol";

/**
    @title RariFundManager
    @notice Handles deposits and withdrawals into the pool
    @author Jet Jadeja (jet@rari.capital)
*/
contract RariFundManager is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ///@dev The address of the RariFundController Contract
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

    ///@dev Ensures that a function can only be called from the RariFundController
    modifier onlyController() {
        require(
            msg.sender == rariFundControllerContract,
            "RariFundManager: Function must be called by the Fund Controller"
        );
        _;
    }

    constructor(address _rariFundControllerContract) public Ownable() {
        addSupportedCurrency("BAT", 0x0D8775F648430679A709E98d2b0Cb6250d2887EF, 18);
        addSupportedCurrency("COMP", 0xc00e94Cb662C3520282E6f5717214004A7f26888, 18);
        addSupportedCurrency("WBTC", 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 8);
        addSupportedCurrency("UNI", 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 18);
        addSupportedCurrency("USDC", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 6);
        addSupportedCurrency("USDT", 0xdAC17F958D2ee523a2206206994597C13D831ec7, 6);
        addSupportedCurrency("ZRX", 0xE41d2489571d322189246DaFA5ebDe1F4699F498, 18);

        rariFundControllerContract = _rariFundControllerContract;
        rariFundController = RariFundController(_rariFundControllerContract);
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
    ) internal {
        currencyIndexes[currencyCode] = supportedCurrencies.length;
        supportedCurrencies.push(currencyCode);
        currencyAddresses[currencyCode] = currencyAddress;
        currencyDecimals[currencyCode] = decimals;
    }

    /**
        @dev Deposit funds into the contract and send them to the FundController
        @param currencyCode The currency code of the asset 
        @param amount The amount of the asset to be deposited
    */
    function deposit(string calldata currencyCode, uint256 amount) external {
        address erc20TokenContract = currencyAddresses[currencyCode];
        //prettier-ignore
        require(erc20TokenContract != address(0), "RariFundManager: Invalid Currency Code");
        rariFundController.deposit(erc20TokenContract, msg.sender, amount);
    }
}
