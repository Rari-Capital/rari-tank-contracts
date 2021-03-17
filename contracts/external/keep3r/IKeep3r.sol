pragma solidity 0.7.3;

interface IKeep3r {
    function worked(address) external;
    function addJob(address) external;

    function jobs(address) external returns (bool);
    function addCreditETH(address) external payable;
    function isKeeper(address) external returns (bool);
}