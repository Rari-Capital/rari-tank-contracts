pragma solidity ^0.7.0;

import "../external/rari/IRariFundManager.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library RariPoolController {
    using SafeMath for uint256;

    address constant rariFundManager = 0xC6BF8C8A55f77686720E0a88e2Fd1fEEF58ddf4a;

    function deposit(
        string memory currencyCode,
        address underlying,
        uint256 amount
    ) internal {
        IERC20(underlying).approve(rariFundManager, amount);
        IRariFundManager(rariFundManager).deposit(currencyCode, amount);
    }

    function withdraw(string memory currencyCode, uint256 amount) internal {
        IRariFundManager(rariFundManager).withdraw(currencyCode, amount);
    }

    function getUSDBalance() internal returns (uint256) {
        return IRariFundManager(rariFundManager).balanceOf(address(this));
    }
}
