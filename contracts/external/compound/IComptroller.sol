pragma solidity 0.7.3;

/**
    @title Compound's Comptroller Contract
    @author Compound
 */
interface IComptroller {
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);
    function markets(address)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function enterMarkets(address[] calldata) external returns (uint256[] memory);
}
