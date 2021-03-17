pragma solidity ^0.7.3;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint256) external;
    function balanceOf(address) external returns (uint256);
}
