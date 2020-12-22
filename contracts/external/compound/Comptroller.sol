pragma solidity ^0.5.0;

interface Comptroller {
    function markets(address) external returns (bool, uint256);

    function enterMarkets(address[] calldata) external returns (uint256[] memory);
}
