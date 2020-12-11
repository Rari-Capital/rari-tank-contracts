pragma solidity ^0.5.0;

import "./FundManager.sol";
import "./external/compound/CErc20.sol";
import "./external/compound/Comptroller.sol";
import "./external/compound/PriceFeed.sol";

import "@openzeppelin/contracts/token/erc20/IERC20.sol";

contract FundController {
    ///@dev The Fund Manager Smart  Contract
    address private fundManager;

    ///@dev Maps the amount of each cToken this address holds
    mapping(address => uint256) private cTokenBalances;

    ///@dev Maps user address to the address of their deposited token
    mapping(address => address) private usedToken;

    ///@dev Ensure that the modified function can only be called by the fundManager
    modifier onlyManager() {
        require(
            address(msg.sender) == fundManager,
            "Function must be called by the FundManager"
        );
        _;
    }

    /**
        @dev Internal function to deposit collateral into Compound
        @param _underlyingToken The token that is used as collateral
        @param _amount The amount of _underlyingToken to be supplied
        @param _cToken The address of the Compound Token
        @param _comptroller The address of the comptroller
    */
    function _deposit(
        address _underlyingToken,
        uint256 _amount,
        address _cToken,
        address _comptroller
    ) internal {
        // Ensure that the user doesn't deposit more than 1 currency
        require(
            usedToken[msg.sender] == address(0) ||
                usedToken[msg.sender] == _underlyingToken,
            "RariFundController: Token Type must match deposits"
        );

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

    function deposit(address tokenContract, address cTokenContract)
        external
        onlyManager()
    {}

    function _withdraw(address _comptroller) internal {
        Comptroller comptroller = Comptroller(_comptroller);

        (uint256 error, uint256 liquidity, uint256 shortfall) =
            comptroller.getAccountLiquidity(address(this));

        if (error != 0) {
            revert("Comptroller: Failed to get account liquidity");
        }

        require(shortfall == 0, "Comptroller: account underwater");
        require(liquidity > 0, "Comptroller: account has excess collateral");
    }
}
