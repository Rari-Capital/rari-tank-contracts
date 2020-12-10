pragma solidity ^0.5.0;

interface IComptroller {
  function markets(address) external returns (bool, uint256);

  function enterMarkets(address[] calldata) external returns (uint256[] memory);

  function getAccountLiquidity(address)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}
