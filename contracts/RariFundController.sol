pragma solidity ^0.7.0;

contract RariFundController {
    address private rariFundManager;

    constructor(address _rariFundManager) {
        rariFundManager = _rariFundManager;
    }

    function deposit(address account, uint256 amount) external {}
}
