pragma solidity ^0.7.3;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    
    function balanceOf(address) external returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}
