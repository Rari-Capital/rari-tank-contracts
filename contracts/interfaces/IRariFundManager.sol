pragma solidity 0.7.3;

/**
    @title IRariFundManager
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariFundManager {
    function deposit(address, uint256) external;
    function withdraw(address, uint256) external;
    function rebalance(address) external;
}