pragma solidity ^0.5.0;

import "./libraries/CompoundPoolController.sol";

/**
    @title RariFundController
    @notice Holds the funds handling deposits and withdrawals into Compound and the Rari Stable Pool 
    @author Jet Jadeja (jet@rari.capital) 
*/
contract RariFundController {
    ///@dev The address of the RariFundManager contract
    address private rariFundManagerContract;

    constructor(address _rariFundManagerContract) public {
        rariFundManagerContract = _rariFundManagerContract;
    }

    ///@dev Ensures that a function can only be called from the RariFundController
    modifier onlyFundManager() {
        //prettier-ignore
        require(msg.sender == rariFundManagerContract, "RariFundController: Function must be called by the Fund Manager");
        _;
    }
}
