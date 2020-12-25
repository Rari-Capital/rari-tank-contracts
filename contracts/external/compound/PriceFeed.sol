pragma solidity ^0.7.0;

/**
    @title Compound's PriceFeed Contract
    @author Compound
 */
interface PriceFeed {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}
