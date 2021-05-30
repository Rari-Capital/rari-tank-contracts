pragma solidity ^0.7.3;

/**
    @title IRariFundTank
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariTank {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function rebalance(bool) external;

    function supplyKeeperPayment(uint256) external returns (address, uint256);

    function exchangeRateCurrent() external returns (uint256);
}
