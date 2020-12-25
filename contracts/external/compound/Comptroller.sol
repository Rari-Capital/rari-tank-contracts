pragma solidity ^0.7.0;

/**
    @title Compound's Comptroller Contract
    @author Compound
 */
interface Comptroller {
    function markets(address) external returns (bool, uint256);

    function enterMarkets(address[] calldata) external returns (uint256[] memory);
}
