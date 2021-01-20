pragma solidity ^0.7.0;

import "../external/compound/ICErc20.sol";
import "../external/compound/IComptroller.sol";
import "../external/compound/IPriceFeed.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @title CompoundPoolController
    @author David Lucid (david@rari.capital), Jet Jadeja (jet@rari.capital)
    @dev This library is used to handle interactions with Compound
*/
library CompoundPoolController {
    using SafeMath for uint256;

    //@dev The address of Compound's Comptroller
    address constant comptrollerContract = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    /**
        @dev Deposits collateral into Compound
        @param underlying The address of the underlying asset
        @param amount The amount of the asset being supplied
    */
    function deposit(
        address underlying,
        uint256 amount
    ) internal {
        require(amount > 0, "CompoundPoolController: Amount must be greater than 0");

        address cErc20Contract = getCErc20Contract(underlying);
        ICErc20 cToken = ICErc20(cErc20Contract);
        IComptroller comptroller = IComptroller(comptrollerContract);

        // Approve the transfer of the ERC20 Contract
        IERC20(underlying).approve(cErc20Contract, amount);

        // Mint cTokens in return for the underlying asset
        uint256 error = cToken.mint(amount);
        require(error == 0, "CERC20: Mint Error");

        // Enter markets
        address[] memory cTokens = new address[](1);
        cTokens[0] = cErc20Contract;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);

        require(errors[0] == 0, "Comptroller: Failed to enter markets");
    }

    /**
        @dev Withdraws funds from Compound
        @param underlying The address of the underlying asset
        @param amount The amount to be withdrew
    */
    function withdraw(address underlying, uint256 amount) internal {
        ICErc20 cToken = ICErc20(getCErc20Contract(underlying));

        uint256 error = cToken.redeemUnderlying(amount);
        require(error == 0, "CompoundPoolController: Compound redeem error");
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
    }

    function repayBorrow(address underlying, uint256 amount) internal {
        address cErc20Contract = getCErc20Contract(underlying);
        IERC20(underlying).approve(cErc20Contract, amount);
        uint256 error = ICErc20(getCErc20Contract(underlying)).repayBorrow(amount);

        require(error == 0, "CompoundPoolController: Compound Repay Error");
    }

    /**
        @dev Get the balanceOfUnderlying
    */
    function balanceOfUnderlying(address underlying) internal returns(uint256) {
        return ICErc20(getCErc20Contract(underlying)).balanceOfUnderlying(address(this));
    }

    function borrowBalanceCurrent(address underlying) internal returns(uint256) {
        return ICErc20(getCErc20Contract(underlying)).borrowBalanceCurrent(address(this));
    }

    /**
        @dev Returns a token's cToken contract address given its ERC20 contract address.
        @param underlying The address of the underlying asset 
    */
    function getCErc20Contract(address underlying) private pure returns (address) {
        if (underlying == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return 0x35A18000230DA775CAc24873d00Ff85BccdeD550; // UNI => cUNI
        if (underlying == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC => cUSDC
        if (underlying == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4; // WBTC => cWBTC
        if (underlying == 0xE41d2489571d322189246DaFA5ebDe1F4699F498) return 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407; // ZRX => cZRX
        else revert("CompoundPoolController: Supported cToken address not found for this token address");
    }
}
