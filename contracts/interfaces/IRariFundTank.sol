pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @title IRariFundTank
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariFundTank is IERC20 {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;

    function rebalance() external;
    function exchangeRateCurrent() external;
}