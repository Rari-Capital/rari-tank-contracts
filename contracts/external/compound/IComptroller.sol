pragma solidity ^0.7.0;

/**
    @title Compound's Comptroller Contract
    @author Compound
 */
interface IComptroller {
    //prettier-ignore
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

    function markets(address) external returns (bool, uint256);

    function enterMarkets(address[] calldata) external returns (uint256[] memory);
}
