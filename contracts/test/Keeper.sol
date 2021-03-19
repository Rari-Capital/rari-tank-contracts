pragma solidity 0.7.3;

import {IKeep3r} from "../external/keep3r/IKeep3r.sol";
import {IRariTank} from "../interfaces/IRariTank.sol";
import {IRariTankFactory} from "../interfaces/IRariTankFactory.sol";

/**
    @dev Keeper used in tests
*/
contract Keeper {
    IKeep3r internal constant KPR = IKeep3r(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    IRariTankFactory internal factory;
    
    constructor(address _factory) {
        factory = IRariTankFactory(_factory);
        KPR.bond(address(KPR), 0);
    }

    /**
        @dev Activate the bot
    */
    function activate() external {
        KPR.activate(address(KPR));
    }

    /** @dev Rebalance the tank */
    function rebalance(address tank) external {
        IRariTank(tank).rebalance();
    }
}