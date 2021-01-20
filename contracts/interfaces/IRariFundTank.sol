pragma solidity ^0.7.0;

interface IRariFundTank {
    function deposit(address, uint256) external;

    function withdraw(address, uint256) external returns (address, uint256);

    function rebalance() external;

    function getTokenExchangeRate() external returns (uint256);
}
