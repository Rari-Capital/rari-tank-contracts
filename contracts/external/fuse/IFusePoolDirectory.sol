pragma solidity 0.7.3;

/**
    @title IFusePoolDirectory
    @author David Lucid <david@rari.capital>
*/
interface IFusePoolDirectory {
    function poolExists(address) external returns (bool);
}
