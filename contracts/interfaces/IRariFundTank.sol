pragma solidity ^0.7.3;

/**
    @title IRariFundTank
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariFundTank{
    function deposit(uint256) external;
    function withdraw(uint256) external;

    function rebalance() external;
    function exchangeRateCurrent() external returns (uint256);
}