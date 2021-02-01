pragma solidity ^0.7.3;

/**
    @title IRariFundTank
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariFundTank{
    function deposit(address, uint256) external;
    function withdraw(address, uint256) external;

    function rebalance() external;
    function exchangeRateCurrent() external returns (uint256);
}