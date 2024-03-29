pragma solidity 0.7.3;

/**
    @title Compound's CErc20 Contract
    @author Compound
 */
interface ICErc20 {
    function underlying() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function mint(uint256) external returns (uint256);
    function redeemUnderlying(uint256) external returns (uint256);
    
    function borrow(uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);

    function balanceOf(address) external returns (uint256);
    function balanceOfUnderlying(address) external returns (uint256);
    function borrowBalanceCurrent(address) external returns (uint256);

    function getCash() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
}
