pragma solidity ^0.5.0;

interface CErc20 {
  function mint(uint256) external returns (uint256);

  function borrow(uint256) external returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);

  function borrowBalanceCurrent(address) external returns (uint256);

  function repayBorrow(uint256) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);
}
