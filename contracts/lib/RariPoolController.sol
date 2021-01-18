pragma solidity ^0.7.0;

import "../external/rari/IRariFundManager.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library RariPoolController {
    using SafeMath for uint256;

    function deposit(
        address rariFundManager,
        string memory currencyCode,
        address underlying,
        uint256 amount
    ) internal {
        IERC20(underlying).approve(rariFundManager, amount);
        IRariFundManager(rariFundManager).deposit(currencyCode, amount);
    }

    function withdraw(
        address rariFundManager,
        string memory currencyCode,
        uint256 amount
    ) internal {
        IRariFundManager(rariFundManager).withdraw(currencyCode, amount);
    }

    function getUSDBalance(address rariFundManager) internal returns (uint256) {
        return IRariFundManager(rariFundManager).balanceOf(address(this)).div(1e12);
    }
}
