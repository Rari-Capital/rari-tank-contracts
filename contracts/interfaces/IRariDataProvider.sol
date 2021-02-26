pragma solidity 0.7.3;

/* Interfaces */
import {IComptroller} from "../external/compound/IComptroller.sol";
import {ICErc20} from "../external/compound/ICErc20.sol";

/**
    @title IRariDataProvider
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariDataProvider {
    
    function borrowBalanceCurrent(ICErc20) external returns (uint256);
    function maxBorrowAmountUSD(IComptroller, address, uint256) external returns (uint256);

    function convertUnderlyingToCErc20(ICErc20, uint256) external returns (uint256);
    function convertCErc20ToUnderlying(ICErc20, uint256) external returns (uint256);
    function convertUSDToUnderlying(IComptroller, address, uint256) external returns (uint256);

    
    function getUnderlyingPrice(IComptroller, address) external view returns (uint256);
}