pragma solidity ^0.7.0;

/**
    @title Compound's CErc20 Contract
    @author Compound
 */
interface ICErc20 {
    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
}
