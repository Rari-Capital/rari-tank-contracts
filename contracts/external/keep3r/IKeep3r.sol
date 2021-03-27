pragma solidity 0.7.3;

interface IKeep3r {
    function worked(address) external;
    function receiptETH(address, uint) external;
    function jobs(address) external returns (bool);
    function isKeeper(address) external returns (bool);
    
    function activate(address) external;
    function bond(address, uint) external;

    function addJob(address) external;
    function addCreditETH(address) external payable;
}