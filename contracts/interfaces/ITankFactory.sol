pragma solidity 0.7.3;

/** 
    @title ITankFactory
    @author Jet Jadeja <jet@rari.capital>
*/
interface ITankFactory {
    function deployTank(
        address,
        address,
        address,
        address
    ) external;

    function reblanace(address) external;

    function idByTank(address) external view returns (uint256);

    function implementationById(uint256) external view returns (address);
}
