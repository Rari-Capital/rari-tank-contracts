pragma solidity ^0.5.0;

interface PriceFeed {
  function getUnderlyingPrice(address cToken) external view returns (uint256);
}
