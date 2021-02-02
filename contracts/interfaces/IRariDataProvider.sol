pragma solidity 0.7.3;

/* Interfaces */
import {IPriceFeed} from "../external/compound/IPriceFeed.sol";
import {IComptroller} from "../external/compound/IComptroller.sol";

/**
    @title IRariDataProvider
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariDataProvider {
    
    function borrowBalanceCurrent(address) external returns (uint256);
    function maxBorrowAmountUSD(IComptroller, address, uint256) external returns (uint256);

    function convertUnderlyingToCErc20(address, uint256) external returns (uint256);
    function convertCErc20ToUnderlying(address, uint256) external returns (uint256);
    function convertUSDToUnderlying(IPriceFeed, address, uint256) external returns (uint256);

    
    function getUnderlyingPrice(IPriceFeed, address) external view returns (uint256);
}