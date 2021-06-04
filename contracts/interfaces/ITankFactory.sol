pragma solidity 0.7.3;

/** 
    @title ITankFactory
    @author Jet Jadeja <jet@rari.capital>
*/
interface ITankFactory {
    function deployTank(
        address,
        address,
        uint256
    ) external;
    function newImplementation(address) external returns (uint256);
    function reblanace(address) external;
}
