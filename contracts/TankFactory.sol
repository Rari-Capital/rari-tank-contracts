pragma solidity 0.7.3;

/* Storage */
import {TankFactoryStorage} from "./factory/TankFactoryStorage.sol";

/* Interfaces */
import {ITankFactory} from "./interfaces/ITankFactory.sol";

/**
    @title TankFactory
    @author Jet Jadeja <jet@rari.capital>
    @dev Manages Tank deployments, new strategies, and rebalances
*/
contract TankFactory is TankFactoryStorage {
    /********************
     * External Functions *
     *********************/

    /** @dev Deploy a new Tank contract */
    function deployTank(
        address token,
        address comptroller,
        uint256 implementationId
    ) external override {}

    /** @dev Register a new implementaiton contract */
    function newImplementation(address) external override returns (uint256) {}

    function reblanace(address) external override {}
}
