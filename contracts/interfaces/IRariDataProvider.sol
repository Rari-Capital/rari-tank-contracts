pragma solidity 0.7.3;

/* Interfaces */
import {IComptroller} from "../external/compound/IComptroller.sol";
import {ICErc20} from "../external/compound/ICErc20.sol";

/**
    @title IRariDataProvider
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariDataProvider {
    
    function borrowBalanceCurrent(address, address) external returns (uint256);
    function maxBorrowAmountUSD(address, address, uint256) external returns (uint256);

    function convertUSDToUnderlying(address, address, uint256) external returns (uint256);

    function getUnderlyingInEth(address, address) external returns (uint256);
    function getUnderlyingPrice(address, address) external returns (uint256);
}