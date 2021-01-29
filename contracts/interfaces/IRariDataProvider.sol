pragma solidity 0.7.3;

/**
    @title IRariDataProvider
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariDataProvider {
    function maxBorrowAmountUSD(address, uint256) external;
    function getPriceOfUnderlying(address, uint256) external;

    function convertUSDToUnderlying(address, uint256) external;
    function convertUnderlyingToCErc20(address, uint256) external;
    function convertCErc20ToUnderlying(address, uint256) external;

    function balanceOfUnderlying(address, address) external;
    function borrowBalanceCurrent(address, address) external;
    
}