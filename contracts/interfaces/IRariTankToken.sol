pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRariTankToken is IERC20 {
    function mint(address, uint256) external;

    function burnFrom(address, uint256) external;

    function initialize() external;
}
