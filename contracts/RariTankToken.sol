pragma solidity ^0.7.0;

import "./interfaces/IRariFundTank.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract RariTankToken is ERC20, ERC20Burnable, Initializable {
    address private rariFundTank;

    modifier onlyFundTank() {
        require(msg.sender == rariFundTank, "RariTankToken: RariFundTank");
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function initialize() public initializer() {
        rariFundTank = msg.sender;
    }

    function mint(address account, uint256 amount) external onlyFundTank {
        _mint(account, amount);
    }
}
