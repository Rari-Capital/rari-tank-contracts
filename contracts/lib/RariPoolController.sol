pragma solidity ^0.7.0;

import "../external/rari/IRariFundManager.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library RariPoolController {
    function deposit(
        address rariFundManager,
        string memory currencyCode,
        address underlying,
        uint256 amount
    ) internal {
        IERC20(underlying).approve(rariFundManager, amount);
        bool error = IRariFundManager(rariFundManager).deposit(currencyCode, amount);

        require(error, "RariPoolController: Rari Pool Deposit Error");
    }

    function withdraw(
        address rariFundManager,
        string memory currencyCode,
        address underlying,
        uint256 amount
    ) internal {
        IERC20(underlying).approve(rariFundManager, amount);
        bool error = IRariFundManager(rariFundManager).withdraw(currencyCode, amount);

        require(error, "RariPoolController: Rari Pool Withdrawal Error");
    }

    function getUSDBalance(address rariFundManager, string memory currencyCode)
        internal
        returns (uint256)
    {
        return IRariFundManager(rariFundManager).getRawFundBalance(currencyCode);
    }
}
