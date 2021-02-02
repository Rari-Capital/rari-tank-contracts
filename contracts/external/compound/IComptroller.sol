pragma solidity 0.7.3;

import {IPriceFeed} from "./IPriceFeed.sol";

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
    function oracle() external returns (IPriceFeed);
}
