pragma solidity 0.7.3;

/**
    @title IRariTankFactory
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariTankFactory {
    function rebalance(address) external;
    function deployTank(address, address, address) external returns (address);
}