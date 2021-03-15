pragma solidity 0.7.3;

interface IKeep3r {
    function addCreditETH(address job) external payable;
    function isKeeper(address) external returns (bool);
    function worked(address) external;
}