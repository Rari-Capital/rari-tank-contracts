pragma solidity 0.7.3;

/**
    @title IRariTankFactory
    @author Jet Jadeja <jet@rari.capital>
*/
interface IRariTankFactory {
    function rebalance(address, bool) external;

    function deployTank(
        address,
        address,
        address,
        address
    ) external returns (address);

    function idByTank(address) external view returns (uint256);

    function implementationById(uint256) external view returns (address);
}
