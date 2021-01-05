pragma solidity ^0.7.0;

interface RariFundManager {
    function balanceOf(address) external returns (uint256);

    function getRawFundBalance(string memory) external returns (uint256);

    function deposit(string calldata, uint256) external returns (bool);

    function withdraw(string calldata, uint256) external returns (bool);
}
