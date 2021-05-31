pragma solidity 0.7.3;

/** 
    @title ITank
    @author Jet Jadeja <jet@rari.capital)
*/
interface ITank {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function rebalance(bool) external;

    function exchangeRateCurrent() external returns (uint256);
    function supplyKeeperPayment(uint256) external returns (address, uint256);
}
