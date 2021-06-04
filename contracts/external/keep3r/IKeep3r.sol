pragma solidity 0.7.3;

interface IKeep3r {
    function isKeeper(address) external returns (bool);
    function jobs(address) external returns (bool);
    function addJob(address) external;

    function addCreditETH(address) external payable;
    function receiptETH(address, uint256) external;
    function addCredit(
        address,
        address,
        uint256
    ) external;

    function activate(address) external;
    function bond(address, uint256) external;

    function ETH() external view returns (address);
    function credits(address) external view returns (uint256);

    function receipt(
        address,
        address,
        uint256
    ) external;

}
