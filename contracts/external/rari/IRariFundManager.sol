pragma solidity 0.7.3;

interface IRariFundManager {
    function balanceOf(address) external returns (uint256);
    function deposit(string calldata, uint256) external;
    function withdraw(string calldata, uint256) external;
}
