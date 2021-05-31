pragma solidity 0.7.3;

import {IPriceFeed} from "./IPriceFeed.sol";
import {ICErc20} from "./ICErc20.sol";
/**
    @title Compound's Comptroller Contract
    @author Compound
 */
interface IComptroller {
    function oracle() external view returns (IPriceFeed);
    function cTokensByUnderlying(address) external view returns (ICErc20);
    
    function markets(address) external view returns (bool, uint256);
    function enterMarkets(address[] calldata) external returns (uint256[] memory);
    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
}
